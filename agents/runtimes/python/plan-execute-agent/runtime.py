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


def parse_json(content: str) -> dict[str, Any]:
    content = content.strip()

    if content.startswith("```"):
        content = content.split("\n", 1)[1]
        content = content.rsplit("```", 1)[0]

    return json.loads(content)


def create_plan(
    client: OpenAI,
    model: str,
    agent: dict[str, Any],
    tools: list[dict[str, Any]],
    user_prompt: str,
) -> list[dict[str, str]]:
    tool_descriptions = "\n".join(
        f"- {tool['function']['name']}: {tool['function']['description']}"
        for tool in tools
    )

    response = client.chat.completions.create(
        model=model,
        messages=[
            {
                "role": "system",
                "content": (
                    f"{agent['instructions']}\n\n"
                    "Create a small, ordered plan of the tool calls needed to answer the user's request.\n"
                    "Each step must use exactly one tool from this list:\n"
                    f"{tool_descriptions}\n\n"
                    "Do not include reasoning or final-answer steps.\n"
                    "Do not execute the steps and do not call tools.\n\n"
                    "Return only valid JSON in this format:\n"
                    '{"steps": [{"description": "Step description", '
                    '"tool": "tool_name"}]}'
                ),
            },
            {
                "role": "user",
                "content": user_prompt,
            },
        ],
    )

    content = response.choices[0].message.content or ""
    plan = parse_json(content)

    return plan["steps"]


def execute_step(
    client: OpenAI,
    model: str,
    agent: dict[str, Any],
    tools: list[dict[str, Any]],
    functions: dict[str, Any],
    user_prompt: str,
    plan: list[dict[str, str]],
    step_number: int,
    previous_results: list[str],
) -> str:
    step = plan[step_number]
    step_tool = step["tool"]
    step_tools = [
        tool for tool in tools if tool["function"]["name"] == step_tool
    ]

    previous_context = "\n\n".join(
        f"Step {index + 1} result:\n{result}"
        for index, result in enumerate(previous_results)
    )

    messages = [
        {
            "role": "system",
            "content": (
                f"{agent['instructions']}\n\n"
                "You are executing one step from an existing plan.\n"
                f"Call only the {step_tool} tool exactly once.\n"
                "Complete only the current step."
            ),
        },
        {
            "role": "user",
            "content": (
                f"Original request:\n{user_prompt}\n\n"
                f"Complete plan:\n"
                f"{json.dumps(plan, indent=2)}\n\n"
                f"Current step {step_number + 1}:\n{step['description']}\n\n"
                f"Previous step results:\n"
                f"{previous_context or 'None'}"
            ),
        },
    ]

    # First make the one tool call assigned to this plan step.
    response = client.chat.completions.create(
        model=model,
        messages=messages,
        tools=step_tools,
        tool_choice={"type": "function", "function": {"name": step_tool}},
    )
    message = response.choices[0].message
    messages.append(message.model_dump(exclude_none=True))

    for tool_call in message.tool_calls or []:
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

        return json.dumps(result)

    return ""


def create_final_answer(
    client: OpenAI,
    model: str,
    agent: dict[str, Any],
    user_prompt: str,
    plan: list[str],
    step_results: list[str],
) -> str:
    execution_results = "\n\n".join(
        (
            f"Step {index + 1}: {plan[index]['description']}\n"
            f"Result: {result}"
        )
        for index, result in enumerate(step_results)
    )

    response = client.chat.completions.create(
        model=model,
        messages=[
            {
                "role": "system",
                "content": (
                    f"{agent['instructions']}\n\n"
                    "The plan has been executed. Use the execution results "
                    "to provide the final answer to the user. Do not create "
                    "another plan and do not call tools."
                ),
            },
            {
                "role": "user",
                "content": (
                    f"Original request:\n{user_prompt}\n\n"
                    f"Execution results:\n{execution_results}"
                ),
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

    # First, create a structured plan.
    plan = create_plan(
        client=client,
        model=model,
        agent=agent,
        tools=tools,
        user_prompt=user_prompt,
    )

    print("Plan:")

    for index, step in enumerate(plan, start=1):
        print(f"{index}. {step['description']} ({step['tool']})")

    print()

    # Execute each planned step separately.
    step_results = []

    for step_number, step in enumerate(plan):
        print(f"Executing step {step_number + 1}: {step['description']}")

        result = execute_step(
            client=client,
            model=model,
            agent=agent,
            tools=tools,
            functions=functions,
            user_prompt=user_prompt,
            plan=plan,
            step_number=step_number,
            previous_results=step_results,
        )

        step_results.append(result)

        print(f"Step result: {result}")
        print()

    # Combine all step results into one final user-facing answer.
    final_answer = create_final_answer(
        client=client,
        model=model,
        agent=agent,
        user_prompt=user_prompt,
        plan=plan,
        step_results=step_results,
    )

    print("Final answer:")
    print(final_answer)


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