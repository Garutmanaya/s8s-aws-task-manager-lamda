import boto3, uuid, json, datetime, os

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TASKS_TABLE'])

def lambda_handler(event, context):
    user_id = event['requestContext']['authorizer']['claims']['sub']
    data = json.loads(event['body'])

    task_id = str(uuid.uuid4())
    now = datetime.datetime.utcnow().isoformat()

    item = {
        'userId': user_id,
        'taskId': task_id,
        'description': data['description'],
        'status': 'OPEN',
        'targetDate': data.get('targetDate', ''),
        'closedDate': '',
        'createdAt': now,
        'updatedAt': now
    }

    table.put_item(Item=item)
    return {'statusCode': 201, 'body': json.dumps(item)}
