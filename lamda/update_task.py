import boto3, json, datetime, os

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TASKS_TABLE'])

def lambda_handler(event, context):
    user_id = event['requestContext']['authorizer']['claims']['sub']
    data = json.loads(event['body'])
    task_id = data['taskId']

    now = datetime.datetime.utcnow().isoformat()
    update_expr = "SET description=:desc, targetDate=:target, updatedAt=:upd"
    expr_vals = {
        ":desc": data['description'],
        ":target": data['targetDate'],
        ":upd": now
    }

    table.update_item(
        Key={'userId': user_id, 'taskId': task_id},
        UpdateExpression=update_expr,
        ExpressionAttributeValues=expr_vals
    )
    return {'statusCode': 200, 'body': json.dumps({'message': 'Task updated'})}
