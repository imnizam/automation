import groovy.json.JsonSlurper

def json_slurper = new JsonSlurper()

def dockerRegistrySearchURL="curl http://docker-registry.myorg.vpc/v2/phantom/tags/list"

def tagsList = dockerRegistrySearchURL.execute()
// print tagsList.text
def object = json_slurper.parseText(tagsList.text)
def tagArr = object.tags
// print tagArr

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

// print arr

arr.sort{ String a, String b ->
  def a1 = a.split("-")[0].drop(1).isInteger() ? a.split("-")[0].drop(1).toInteger() : null
  def b1 = b.split("-")[0].drop(1).isInteger() ? b.split("-")[0].drop(1).toInteger() : null
  a1 <=> b1
}
def id_array = arr.reverse()
int display_size = 10;
def list = [];
String image_url = ""
String image_tag = ""
for(p=0; p < display_size && p < id_array.size(); p++)
{
  image_tag = id_array[p]
   list.add(image_tag)
}

return list;



