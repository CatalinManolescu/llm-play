import argparse
import importlib
import json
import sys
from pathlib import Path
from typing import Any

import yaml
from openai import OpenAI


def load_agent(path: str) -> dict[str, Any]:
    sys.path.insert(0, str(Path(path).resolve().parent))

    with Path(path).open(encoding="utf-8") as file:
        return yaml.safe_load(file)


def load_functions(agent: dict[str, Any]) -> dict[str, Any]:
    return {
        tool["name"]: load_function(tool["function"])
        for tool in agent["tools"]
    }


def build_tools(agent: dict[str, Any]) -> list[dict[str, Any]]:
    return [
        {
            "type": "function",
            "function": {
                "name": tool["name"],
                "description": tool["description"],
                "parameters": tool["parameters"],
            },
        }
        for tool in agent["tools"]
    ]


def load_function(function_path: str):
    module_name, function_name = function_path.rsplit(".", 1)
    module = importlib.import_module(module_name)
    return getattr(module, function_name)


def create_plan(
    client: OpenAI,
    model: str,
    agent: dict[str, Any],
    user_prompt: str,
) -> str:
    response = client.chat.completions.create(
        model=model,
        messages=[
            {
                "role": "system",
                "content": (
                    f"{agent['instructions']}\n\n"
                    "Create a short step-by-step plan for completing the "
                    "user's request. Do not execute the plan and do not call "
                    "tools. Return only the plan."
                ),
            },
            {
                "role": "user",
                "content": user_prompt,
            },
        ],
    )

    return response.choices[0].message.content or ""


def run(
    url: str,
    api_key: str,
    model: str,
    agent_path: str,
    user_prompt: str,
) -> None:
    agent = load_agent(agent_path)
    tools = build_tools(agent)
    functions = load_functions(agent)

    client = OpenAI(
        base_url=url,
        api_key=api_key,
    )

    # The planner first creates an explicit plan.
    plan = create_plan(
        client=client,
        model=model,
        agent=agent,
        user_prompt=user_prompt,
    )

    print("Plan:")
    print(plan)
    print()

    messages = [
        {
            "role": "system",
            "content": (
                f"{agent['instructions']}\n\n"
                "Follow the plan below while completing the request.\n\n"
                f"{plan}"
            ),
        },
        {
            "role": "user",
            "content": user_prompt,
        },
    ]

    # Execute the request using the plan as guidance.
    while True:
        response = client.chat.completions.create(
            model=model,
            messages=messages,
            tools=tools,
        )

        message = response.choices[0].message
        messages.append(message.model_dump(exclude_none=True))

        if not message.tool_calls:
            print(message.content)
            return

        for tool_call in message.tool_calls:
            function = functions[tool_call.function.name]
            tool_arguments = json.loads(tool_call.function.arguments)

            print(f"Calling {tool_call.function.name}({tool_arguments})")

            result = function(**tool_arguments)

            messages.append(
                {
                    "role": "tool",
                    "tool_call_id": tool_call.id,
                    "content": json.dumps(result),
                }
            )


def parse_arguments():
    parser = argparse.ArgumentParser()
    parser.add_argument("--url", required=True)
    parser.add_argument("--api-key", required=True)
    parser.add_argument("--model", required=True)
    parser.add_argument("--agent", required=True)
    parser.add_argument("--prompt", required=True)
    return parser.parse_args()


if __name__ == "__main__":
    args = parse_arguments()

    run(
        url=args.url,
        api_key=args.api_key,
        model=args.model,
        agent_path=args.agent,
        user_prompt=args.prompt,
    )