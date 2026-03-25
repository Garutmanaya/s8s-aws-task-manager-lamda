import boto3, json, datetime, os

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TASKS_TABLE'])

def lambda_handler(event, context):
    user_id = event['requestContext']['authorizer']['claims']['sub']
    data = json.loads(event['body'])
    task_id = data['taskId']

    now = datetime.datetime.utcnow().isoformat()
    table.update_item(
        Key={'userId': user_id, 'taskId': task_id},
        UpdateExpression="SET status=:status, closedDate=:closed, updatedAt=:upd",
        ExpressionAttributeValues={":status": "CLOSED", ":closed": now, ":upd": now}
    )
    return {'statusCode': 200, 'body': json.dumps({'message': 'Task closed'})}
