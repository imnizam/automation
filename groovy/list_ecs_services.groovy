import groovy.json.JsonSlurper
cluster = binding.variables.get('Cluster')
def awsCmd = "aws ecs list-services --region us-west-2 --cluster $cluster"
def proc = awsCmd.execute()
proc.waitFor()
def jsonSlurper = new JsonSlurper()
def object = jsonSlurper.parseText(proc.text)
def serviceArray = object.serviceArns
int itr = 0
def list = [];
while(serviceArray[itr] != null)
{
  list.add(serviceArray[itr].split("/")[1]);
  itr++;
}
return list