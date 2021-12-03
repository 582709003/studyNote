jira是Atlassian下面的一个产品，Atlassian下有很多产品，这些产品的部署方式也有不同的方式，有云部署、服务器部署以及数据中心部署，不同的部署方式的开发方式是不一样的；



与jira server platform集成其实就是使用jira server提供的api自己写一套插件然后安装到jira服务器上，就像在idea上安装插件一样，姑且先这样理解；



我们现在要做的其实就是对jira software做二次开发，改变一些或者增加一些功能



### Jira Software Server API

Jira Software Server API 让您的集成与 Jira Software Server 进行通信。例如，使用 REST API，您可以编写一个脚本，将问题从一个 sprint 移动到另一个 sprint。对于大多数其他集成，您应该使用 REST API。只有在构建 Plugins2 插件时才应使用 Java API。

- [Jira 软件服务器 REST API](https://docs.atlassian.com/jira-software/REST/server/) *（最新生产版本）*
- [Jira 软件服务器 Java API](https://docs.atlassian.com/jira-software/) *（所有版本）*

*注意，Jira Software 是基于 Jira 平台构建的，因此您也可以使用 [Jira Server Platform REST API](https://docs.atlassian.com/jira/REST/server/) （最新）和 [Jira Server Platform Java API](https://docs.atlassian.com/jira/server/) （最新）与 Jira Software Server 交互。*



jira rest api的调用需要在请求头传输权限信息，所以需要设置请求头部，以post请求为例：

CloseableHttpClient client = HttpClients.createDefault();
HttpPost post = new HttpPost("http://IP:HOST/rest/api/2/**");
post.setHeader("Accept", "application/json");
post.setHeader("Content-Type", "application/json;charset=UTF-8");
post.setHeader("Authorization", auth);
其中的auth就是权限信息，组成是：”Basic jira管理员账号:密码“,Basic是固定的，后面的内容需要转base64

Base64 base64 = new Base64();
try {
    //"root:123456"是jira账号拼密码
    return "Basic " + base64.encodeToString("root:123456".getBytes("UTF-8"));
} catch (UnsupportedEncodingException e) {
    System.err.println(e.getMessage());
    return null;
}



## 面板

1. 面板是用作项目排期以及任务拆分用的



创建需求

1、先创建项目，后面所有的什么版本，问题基于此

2、创建面板，产品一般创建看板类型，在这个看板里创建epic，一个项目可以创建多个epic

3、在每个epic下面可以创建story，这样需求就创建结束了



创建版本

1、基于项目可以创建多个版本

2、基于某个版本拉入这个版本需要完成的epic

3、为这个版本可以创建多个迭代，每个迭代完成上面选中的epic下的哪些sory



开发人员

1、可以在迭代的某个任务下面创建子任务，这个子任务就已经具体到前几天做什么，譬如设计数据库，后几天做什么，譬如编码等等

2、然后全部编辑好之后就可以点击开始迭代，然后会自动跳转到面板页面

3、在面板页面会显示当前版本中所有迭代的子任务，你可以选择某个迭代显示当前迭代的子任务

4、开发者需要做的就是根据当前面板显示的每天需要做的任务来进行开发，譬如迭代一说明今天的任务是设计数据库，然后拖拽到doing栏中；下班的时候记录一下今天的工作量，譬如几小时，然后jira会自动计算出剩余工作时间还有多少；如果迭代完成了，就拖拽到done中



dashbord

​	其实就是结合jira提供的表图定制化的设计出你想看到的某个方面的数据，使你一目了然