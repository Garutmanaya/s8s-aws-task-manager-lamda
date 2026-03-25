import boto3, os, json

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TASKS_TABLE'])

def lambda_handler(event, context):
    user_id = event['requestContext']['authorizer']['claims']['sub']
    response = table.query(KeyConditionExpression=boto3.dynamodb.conditions.Key('userId').eq(user_id))
    return {'statusCode': 200, 'body': json.dumps(response['Items'])}
