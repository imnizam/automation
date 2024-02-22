import groovy.json.JsonSlurper

def cluster = binding.variables.get('Cluster')
def service = binding.variables.get('Service')

def ecsCmd = "aws ecs describe-services --region us-west-2 --cluster $cluster  --services $service "

def proc = ecsCmd.execute()
proc.waitFor()
def json_slurper = new JsonSlurper()

def obj = json_slurper.parseText(proc.text)

def taskDefArn = obj.services[0].taskDefinition
def taskCmd = "aws ecs describe-task-definition --region us-west-2  --task-definition $taskDefArn "
def taskproc = taskCmd.execute()
taskproc.waitFor()

def task_object = json_slurper.parseText(taskproc.text)

def image = task_object['taskDefinition']['containerDefinitions'][0]['image']

def current_tag = image.split(":")[1]
def dockerRegistryRepo = image.split(":")[0]
def dockerContainer = dockerRegistryRepo.split("/")
def dockerRegistrySearchURL = "curl http://${dockerContainer[0]}/v2/${dockerContainer[1]}/tags/list"
def tagsList = dockerRegistrySearchURL.execute()
def object = json_slurper.parseText(tagsList.text)
def tagArr = object.tags

int itr = 0;
def arr = [];
def item = ""
while( tagArr[itr] != null)
{
  if(tagArr[itr].substring(0) =~ "v")
  {
    item = tagArr[itr]
    arr.add(item)
  }
  itr++
}

arr.sort{ String a, String b ->
  def a1 = a.split("-")[0].drop(1).isInteger() ? a.split("-")[0].drop(1).toInteger() : null
  def b1 = b.split("-")[0].drop(1).isInteger() ? b.split("-")[0].drop(1).toInteger() : null
  a1 <=> b1
}
def id_array = arr.reverse()

int display_size = 100;
def list = [];
String image_url = ""
String image_tag = ""
for(p=0; p < display_size && p < id_array.size(); p++)
{
  image_tag = id_array[p]
  image_url = "${dockerRegistryRepo}:${image_tag}"
  list.add(image_url)
}
String current_deployed = "Current_Deployed:${dockerRegistryRepo}:${current_tag}"
list.add(0,current_deployed)
return list;
