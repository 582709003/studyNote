# kafka

## 分区和消费者组的关系

1. 同一个分区内的消息只能被同一个组中的一个消费者消费，当消费者数量多于分区数量时，多于的消费者空闲（不能消费数据）
2. 当分区数多于消费者数的时候，有的消费者对应多个分区
3. 当分区数等于消费者数的时候，每个消费者对应一个分区
4. 启动多个消费者组，相同的数据会被不同组的消费者消费多次

**注意**：

1. 消费者组的创建有点像rabbitmq中的消费者端创建队列，并与扇出类型的交换机进行绑定的过程

2. 分区是真正存放消息的，如果有多个分区时，生产者会将消息均匀的分发到不同的分区中

3. 当创建一个消费者组去消费同一个主题的消息时，就有点像将同一个主题复制一份出来，以后

   生产者发送消息时会将消息分发到所有的同一个主题中

## 幂等性

###     生产者消息重复发送问题

1. kafka生产者生产消息到分区，如果直接发送消息，kafka会将消息保存到分区中，但kafka会返回一个ack给生产者，表示当前操作是否成功，是否已经保存了这条消息；如果ack失败，根据底层重试机制，生产者会继续发送没有发送成功的消息，kafka又会保存一条一模一样的数据；

2. .为了实现Producer的幂等性,Kafka引入了Producer ID(即PID)和Sequence Number ；PID:每个新的Produce在初始化的时候会被分配一个唯一的PID,对用户是不可见的；Sequence Numbler:对于每个PID,该Producer发送数据的每个<Topic,Partition>都对应一个从0开始单调递增的Sequence Number,Broker端在缓存中保存了这seq number,对于接收的每条消息,如果其序号比Broker缓存中序号大于1则接受它,否则将其丢弃,这样就可以实现了消息重复提交了.但是只能保证单个Producer对于同一个<Topic,Partition>的Exactly Once语义
   
3. 同一PID同一topic不同partition保存的<Topic, Partition,Seq>相互独立

4. 设置enable.idempotence=true后能够动态调整max.in.flight.requests.per.connection,正常情况下该参数大于1,当重试请求到来且时,batch会根据seq重新添加到队列的合适位置,max.in.flight.requests.per.connection设为1,这样它前面的batch序号都比它小,只有前面的batch都发完了,它才能发,这样就解决了数据发送的乱序问题,但是降低了系统的吞吐量
   
4. 我们看到Producer发送数据封装成对象时的参数，根据参数设定，我们就能将数据放在对应的partition中。指明 partition 的情况下，直接将数据放在对应的 partiton ；
    没有指明 partition 值但有 key 的情况下，将 key 的 hash 值与 topic 的 partition 数进行取余得到 partition 值；
   既没有 partition 值又没有 key 值的情况下，第一次调用时随机生成一个整数（后面每次调用在这个整数上自增），将这个值与 topic 可用的 partition 总数取余得到 partition 值，也就是常说的 round-robin轮询算法。
   
   #### 幂等性实现

   Properties props = new Properties();

    props.put(ProducerConfig.ENABLE_IDEMPOTENCE_CONFIG, "true");


## 分区副本机制

### 生产者分区写入策略

生产者将消息写入到topic时，kafka将根据不同的策略将数据分配到不同的分区中

1. 轮询分区策略

   默认策略，如果生产消息时key为null，则使用轮询算法分配分区

2. 随机分区策略

   基本不用

3. 按key分区分配策略

   将 key 的 hash 值与 topic 的 partition 数进行取余得到 partition 值

4. 自定义分区策略

### 消费者组的rebalance机制

#### rebalance再均衡

kafka中的rebalance称之为再均衡，是kafka中确保消费者组中的所有消费者如何达成一致的，分配订阅的topic的每个分区的机制；

rebalance触发的时机有：

1. 消费者组中消费者的个数发生变化
2. topic的数量发生变化
3. patition的数量发生变化

再均衡的不良影响：

1. 发生rebalance，所有的消费者将暂停工作，共同参与再均衡，直到每个消费者被分配到所要消费的分区为止

### 消费者分区分配策略

1. range范围分配策略

   range范围分配策略是kafka默认的分配策略，它可以确保每个消费者消费的分区数量是均衡的。

   <u>注意：range范围分配策略是针对每个topic的</u>

   配置：配置消费者的patition.assignment.strategy为org.apache.kafka.clients.consumer.RangeAssignor

   算法公式

    n = 分区数量 / 消费者数量

   m = 分区数量 % 消费者数量

   前m个消费者，每个消费者消费n + 1个，剩余每个消费者消费n个

2. roundRobin轮询策略

   RoundRobinAssignor轮询策略是将消费者组内所有消费者以及消费者所订阅的所有topic的partition按字典顺序排序(topic和分区的hashcode进行排序)，然后按照轮询方式逐个将分区以此分配给每个消费者

   配置消费者的patition.assignment.strategy为org.apache.kafka.clients.consumer.RoundRobinAssignor

   ![](C:\xinao\mySomeFiles\myImg\kafka消费者轮询策略图.png)

3. Striky粘性分配策略

   在没有发生rebalance时，和轮询策略是一样的；发生了rebalance时，轮询分配策略，而粘性分配策略会尽量保证和上一次的，只是将新的需要分配的分区，均匀的分配到现有可用的消费者中即可；减少上下文的切换


### 副本机制

1. 副本的目的时冗余备份，当某个broker上的分区数据丢失时，依然可以保障数据可用，因为在其他的broker上的副本是可用的

2. producer的acks参数

   acks配置为0：生产者只管写入，不管是否写入成功，可能会丢失数据，性能最好。

   acks配置为1：生产者会等待leader分区确认接收后，才会发送下一条数据，性能中等。

   acks配置为-1或者all：等待所有副本已经将数据同步后，才会发送下一条数据，性能最慢。

   分区中是有leader和follower的概念，为了确保消费者消费的数据是一致的，只能从分区leader去读写数据，follower做的事情就是同步数据，备份。

## kafka原理

### 分区的leader和follower

1. 在卡夫卡中，每个topic都可以配置多个分区以及多个副本，每个分区都有一个leader以及0个或者多个follower，在创建topic时，kafka会将每个分区的leader均匀的分配在每个broker上，我们正常使用kafka是感觉不到leader和follower存在的，但其实所有读写数据的操作都是由leader完成的，follower复制leader的日志数据文件，如果leader出现故障时，follower会被选举为leader，所以，可以这样说：
   1. kafka中的leader负责读写操作，而follower只负责副本数据的同步
   2. 如果leader出现故障，follower会被选举为leader
   3. follower像一个消费者一样，拉去leader对应分区的数据，并保存到日志数据文件中

![](C:\xinao\mySomeFiles\myImg\kafka原理.png)

![](C:\xinao\mySomeFiles\myImg\kafka_AR.png)

![](C:\xinao\mySomeFiles\myImg\kafka_leader选举.png)

controller：当broker启动的时候，都会创建KafkaController对象，但是集群中只能有一个leader对外提供服务，这些每个节点上的KafkaController会在指定的zookeeper路径下创建临时节点，只有第一个成功创建的节点的KafkaController才可以成为leader，其余的都是follower。当leader故障后，所有的follower会收到通知，再次竞争在该路径下创建节点从而选举新的leader;Kafka集群中多个broker，有一个会被选举为controller leader，负责管理整个集群中分区和副本的状态，比如partition的leader 副本故障，由controller 负责为该partition重新选举新的leader 副本；当检测到ISR列表发生变化，有controller通知集群中所有broker更新其MetadataCache信息；或者增加某个topic分区的时候也会由controller管理分区的重新分配工作；

![](C:\xinao\mySomeFiles\myImg\kafka读写流程.png)



![](C:\xinao\mySomeFiles\myImg\kafka消息不丢失.png)

![](C:\xinao\mySomeFiles\myImg\消费者消息不丢失.png)

​			还有一个就是消费者重复消费，我们可以使用数据库来解决，将offset以及消息数据的写入数据库操作放到一个事务里面，这样的话，一旦offset写入失败，那么事务回滚，就不会出现消息重复消费的过程

   

   



