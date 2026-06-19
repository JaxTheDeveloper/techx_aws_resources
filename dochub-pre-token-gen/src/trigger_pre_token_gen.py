import json


def lambda_handler(event, context):
    # In toàn bộ event gốc từ Cognito
    print("FULL EVENT:")
    print(json.dumps(event, indent=2, ensure_ascii=False))

    request = event.get("request", {})
    response = event.get("response", {})

    # In riêng phần bạn muốn xem
    debug_output = {
        "request": {
            "userAttributes": request.get("userAttributes", {}),
            "groupConfiguration": request.get("groupConfiguration", {
                "groupsToOverride": [],
                "iamRolesToOverride": [],
                "preferredRole": None
            })
        },
        "response": response
    }

    print("DEBUG OUTPUT:")
    print(json.dumps(debug_output, indent=2, ensure_ascii=False))

    groups = (
        request
        .get("groupConfiguration", {})
        .get("groupsToOverride", [])
    )

    if groups:
        event.setdefault("response", {})
        event["response"]["claimsOverrideDetails"] = {
            "groupOverrideDetails": {
                "groupsToOverride": groups
            }
        }

    # In event sau khi đã modify
    print("MODIFIED EVENT:")
    print(json.dumps(event, indent=2, ensure_ascii=False))

    return event