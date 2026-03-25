import json

import close_task
import create_task
import get_tasks
import update_task

CORS_HEADERS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Authorization,Content-Type",
    "Access-Control-Allow-Methods": "GET,OPTIONS,POST,PUT",
}


def _with_cors(response):
    response["headers"] = {**CORS_HEADERS, **response.get("headers", {})}
    body = response.get("body")
    if body is not None and not isinstance(body, str):
        response["body"] = json.dumps(body)
    return response


def _not_found():
    return _with_cors({"statusCode": 404, "body": json.dumps({"message": "Route not found"})})


def _method_not_allowed():
    return _with_cors({"statusCode": 405, "body": json.dumps({"message": "Method not allowed"})})


def lambda_handler(event, context):
    method = event.get("httpMethod")
    resource = event.get("resource") or event.get("path")

    if method == "OPTIONS":
        return _with_cors({"statusCode": 200, "body": ""})

    route_handlers = {
        ("/tasks", "GET"): get_tasks.lambda_handler,
        ("/tasks", "POST"): create_task.lambda_handler,
        ("/tasks", "PUT"): update_task.lambda_handler,
        ("/tasks/close", "POST"): close_task.lambda_handler,
    }

    handler = route_handlers.get((resource, method))
    if handler is None:
        valid_paths = {path for path, _ in route_handlers}
        if resource in valid_paths:
            return _method_not_allowed()
        return _not_found()

    try:
        return _with_cors(handler(event, context))
    except KeyError as exc:
        return _with_cors({"statusCode": 400, "body": json.dumps({"message": f"Missing field: {exc.args[0]}"})})
    except Exception as exc:
        return _with_cors({"statusCode": 500, "body": json.dumps({"message": str(exc)})})
