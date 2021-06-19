BeanFactoryPostprocessor
    BeanFactory的后置处理器：在BeanFactory标准初始化完成之后调用：所有的bean定义已经保存加载到beanfactory，但是
                            bean的实例还未创建
    执行过程
        1、ioc创建容器
        2、执行invokeBeanFactoryPostProcessors方法
            1、直接在beanFactory中找到BeanFactoryPostProcessor组件，并执行他们的方法
            2、在初始化其他组件前面执行

BeanDefinitionRegistryPostProcessor extends BeanFactoryPostProcessor
    postProcessBeanDefinitionRegistry(BeanDefinitionRegistry registry)方法执行时机：
        是在所有bean定义信息将要被加载到beanfactory，bean实例还未创建,这允许在下一个后处理阶段开始之前进一步添加
        bean的注册信息；比BeanFactoryPostprocessor还要早执行；可以在此再注册新的bean
        BeanDefinitionRegistry：bean的定义信息保存中心，以后beanfactory就是按照BeanDefinitionRegistry里面保存的
        每一个bean的定义信息创建bean实例的；
     执行过程
            1、ioc创建容器
            2、refresh,执行invokeBeanFactoryPostProcessors方法
                1、从容器中获取所有的BeanDefinitionRegistryPostProcessor组件
                2、依次触发postProcessBeanDefinitionRegistry方法

ApplicationListener原理
    作用：监听容器中发布的事件，事件驱动模型开发

spring容器的创建过程，配置文件版
    1、构建applicationContext对象
        public ClassPathXmlApplicationContext(
                    String[] configLocations, boolean refresh, @Nullable ApplicationContext parent)
                    throws BeansException {

                super(parent);
                setConfigLocations(configLocations);
                if (refresh) {
                    refresh();
                }
            }

    2、里面调用refresh方法
        这里简单说下为什么是 refresh()，而不是 init() 这种名字的方法。因为 ApplicationContext 建立起来以后，
        其实我们是可以通过调用 refresh() 这个方法重建的，refresh() 会将原来的 ApplicationContext 销毁，
        然后再重新执行一次初始化操作
    注解版
        public void refresh() throws BeansException, IllegalStateException {
    		// 来个锁，不然 refresh() 还没结束，你又来个启动或销毁容器的操作，那不就乱套了嘛
    		synchronized (this.startupShutdownMonitor) {
    			// Prepare this context for refreshing.
    			// 准备工作，记录下容器的启动时间、标记“已启动”状态、处理配置文件中的占位符
    			prepareRefresh();

    			// Tell the subclass to refresh the internal bean factory.
    			// 这步比较关键，这步完成后，配置文件就会解析成一个个 Bean 定义，注册到 BeanFactory 中，
    			// 当然，这里说的 Bean 还没有初始化，只是配置信息都提取出来了，
    			// 注册也只是将这些信息都保存到了注册中心(说到底核心是一个 beanName-> beanDefinition 的 map)
    			//loadBeanDefinitions加载bean的定义信息
    			//注解驱动时，加载bean的定义信息与配置文件的不一样
    			//public AnnotationConfigApplicationContext(Class<?>... componentClasses) {
               //     this();
               //     //这里是加载bean的定义信息
               //     register(componentClasses);
               //     refresh();
                //}
    			ConfigurableListableBeanFactory beanFactory = obtainFreshBeanFactory();

    			// Prepare the bean factory for use in this context.
    			// 设置 BeanFactory 的类加载器，添加几个 BeanPostProcessor,
    			譬如ApplicationContextAwareProcessor
    			    实现了 Aware 接口的 beans 在初始化的时候，这个 processor 负责回调，
                    // 这个我们很常用，如我们会为了获取 ApplicationContext 而 implement ApplicationContextAware
                    // 注意：它不仅仅回调 ApplicationContextAware，
                    //   还会负责回调 EnvironmentAware、ResourceLoaderAware
    			// 、ApplicationListenerDetector
    			    这个BeanPostProcessor 也很简单，在 bean 实例化后，如果是 ApplicationListener 的子类，
                    那么将其添加到 listener 列表中，可以理解成：注册事件监听器
    			手动注册几个特殊的 bean，譬如
    			    如果没有定义 "environment" 这个 bean，那么 Spring 会 "手动" 注册一个
                    // 如果没有定义 "systemProperties" 这个 bean，那么 Spring 会 "手动" 注册一个
                    // 如果没有定义 "systemEnvironment" 这个 bean，那么 Spring 会 "手动" 注册一个
    			prepareBeanFactory(beanFactory);

    			try {
    				// Allows post-processing of the bean factory in context subclasses.
    				// 【这里需要知道 BeanFactoryPostProcessor 这个知识点，Bean 如果实现了此接口，
    				// 那么在容器初始化以后，Spring 会负责调用里面的 postProcessBeanFactory 方法。】
    				// 这里是提供给子类的扩展点，到这里的时候，所有的 Bean 都加载、注册完成了，但是都还没有初始化
    				// 具体的子类可以在这步的时候添加一些特殊的 BeanFactoryPostProcessor 的实现类或做点什么事
    				postProcessBeanFactory(beanFactory);

    				// 调用 BeanFactoryPostProcessor 各个实现类的 postProcessBeanFactory(factory)方法
    				invokeBeanFactoryPostProcessors(beanFactory);

    				// Register bean processors that intercept bean creation.
    				// 注册 BeanPostProcessor 的实现类，注册的同时也创建了对象实例，注意看和BeanFactoryPostProcessor
    				    //的区别
    				// 此接口两个方法: postProcessBeforeInitialization 和 postProcessAfterInitialization
    				// 两个方法分别在 Bean 初始化之前和初始化之后得到执行。注意到这里Bean还没初始化
    				registerBeanPostProcessors(beanFactory);

    				// Initialize message source for this context.
    				// 初始化当前 ApplicationContext 的 MessageSource，国际化这里就不展开说了，不然没完没了了
    				initMessageSource();

    				// Initialize event multicaster for this context.
    				// 初始化当前 ApplicationContext 的事件广播器，这里也不展开了
    				initApplicationEventMulticaster();

    				// Initialize other special beans in specific context subclasses.
    				// 从方法名就可以知道，典型的模板方法(钩子方法)，
    				// 具体的子类可以在这里初始化一些特殊的 Bean（在初始化 singleton beans 之前）
    				onRefresh();

    				// Check for listener beans and register them.
    				// 注册事件监听器，监听器需要实现 ApplicationListener 接口。这也不是我们的重点，过
    				registerListeners();

    				// Instantiate all remaining (non-lazy-init) singletons.
    				// 重点，重点，重点
    				// 初始化所有的 singleton beans
    				//（lazy-init 的除外）
    				finishBeanFactoryInitialization(beanFactory);

    				// Last step: publish corresponding event.
    				// 最后，广播事件，ApplicationContext 初始化完成
    				finishRefresh();
    			}

    			catch (BeansException ex) {
    				if (logger.isWarnEnabled()) {
    					logger.warn("Exception encountered during context initialization - " +
    							"cancelling refresh attempt: " + ex);
    				}

    				// Destroy already created singletons to avoid dangling resources.
    				// 销毁已经初始化的 singleton 的 Beans，以免有些 bean 会一直占用资源
    				destroyBeans();

    				// Reset 'active' flag.
    				cancelRefresh(ex);

    				// Propagate exception to caller.
    				// 把异常往外抛
    				throw ex;
    			}

    			finally {
    				// Reset common introspection caches in Spring's core, since we
    				// might not ever need metadata for singleton beans anymore...
    				resetCommonCaches();
    			}
    		}


        注解驱动版，分步解析
            1、prepareRefresh();
                1、initPropertySources();
                    初始化一些属性设置，空的，可以重写他，字类可自定义个性化的属性设置方法

            2、obtainFreshBeanFactory()
                获取BeanFactory；创建了一个DefaultListableBeanFactory，并为其设置序列化id

            3、prepareBeanFactory(beanFactory)
                1、为beanfactory设置类加载器，支持表达式解析器
                2、添加部分postprosessor，如ApplicationContextAwareProcessor
                3、设置忽略的自动装配的接口EnvironmentAware、EmbeddedValueResolverAware......
                    禁止这些接口类型自动装配，如果要装配，需要实现这些接口，重写方法即可
                4、注册可以解析的自动装配，我们能直接在任何组件中自动注入BeanFactory、ResourceLoader、ApplicationEventPublisher、ApplicationContext
                    registerResolvableDependency方法作用
                    在Spring自动装配的时候如果一个接口有多个实现类，并且都已经放到IOC中去了，
                    那么自动装配的时候就会出异常，因为spring不知道把哪个实现类注入进去，
                    但是如果我们自定义一个类，然后实现BeanFactoryPostProcessor接口
                    在该阶段调用这个方法，如果哪个地方要自动注入这个类型的对象的话，那么就注入进去我们指定的对象
                5、添加beanPostProsessor，如ApplicationListenerDetector
                6、添加编译时的aspectj
                7、给容器中注册组件environment、systemProperties、systemEnvironment

            4、postProcessBeanFactory(beanFactory)
                BeanFactory准测i工作完成之后进行的后置处理工作；这里是空实现，字类可以重写这个方法来在BeanFactory创建并预准备完成之后做
                进一步的设置
           ==========================以上是BeanFactory的创建以及预准备工作================================================
            5、invokeBeanFactoryPostProcessors(beanFactory)
                执行BeanFactoryPostProcessor；这是beanFactory的后置处理器，在beanFactory标准初始化之后执行的；
                两个接口BeanDefinitionRegistryPostProcessor、BeanFactoryPostProcessor
                执行过程
                    1、获取所有的BeanDefinitionRegistryPostProcessor
                    2、根据优先级排序，先执行实现PriorityOrdered接口的BeanDefinitionRegistryPostProcessor的方法
                    3、再执行实现Ordered接口的BeanDefinitionRegistryPostProcessor的方法
                    4、最后执行没有实现任何优先级接口或者顺序接口的BeanDefinitionRegistryPostProcessor的方法
                        这个接口允许我们进一步注册bean的定义信信息到容器中或者得到已经注册的bean定义信息并修改它
                    5、再执行BeanFactoryPostProcessor的方法，下面的逻辑与BeanDefinitionRegistryPostProcessor类似
                注意：注解版，是在这个地方通过ConfigurationClassPostProcessor这个后置处理器将我们自定义的需要注入容器
                    的bean的定义信息注册到容器中的；容器中的对象不是完全由注册信息注入的，也可能是容器自己添加的，并且这些添加
                    的对象在注册信息里是没有的，但是所有创建好的对象都会保存在singletonObjects中


            6、registerBeanPostProcessors(beanFactory)
                注册BeanPostProcessors到容器,注册的同时也创建了对象实例，
                BeanPostProcessor、DestructionAwareBeanPostProcessor、InstantiationAwareBeanPostProcessor、
                MergedBeanDefinitionPostProcessor、SmartInstantiationAwareBeanPostProcessor
                不同接口类型的BeanPostProcessor执行时机是不一样的
                MergedBeanDefinitionPostProcessor这个接口对@Autowired和@Value的支持起到了至关重要的作用;
                执行过程
                    1、获取所有的BeanPostProcessor；后置处理器都可以实现PriorityOrdered和Ordered来指定优先级
                    2、把每一个BeanPostProcessor添加到beanFactory中
                    3、最后注册一个ApplicationListenerDetector后置处理器，来在bean创建完之后检查此bean
                        是否是applicationListener，如果是，就保存在容器中
                        this.applicationContext.addApplicationListener((ApplicationListener<?>) bean);

            7、initMessageSource()
                初始化MessageSource组件(做国际化功能，消息绑定，消息解析)

            8、initApplicationEventMulticaster()
                初始化事件多播器
                1、获取beanFactory
                2、从beanFactory获取applicationEventMulticaster
                3、如果没有获取到就创建一个SimpleApplicationEventMulticaster

            9、onRefresh()
                1、留给子容器类做一些其他的事情

            10、registerListeners()
                给容器中注册所有的ApplicationListener
                1、从容器中拿到所有的ApplicationListener,bean的定义信息，然后创建好对象放入容器
                2、将每个监听器添加到事件派发器中
                3、派发之前步骤产生的事件
                    for (ApplicationEvent earlyEvent : earlyEventsToProcess) {
                        getApplicationEventMulticaster().multicastEvent(earlyEvent);
                    }

            11、finishBeanFactoryInitialization(beanFactory)
                初始化剩下的非懒加载的单实例bean
                1、beanFactory.preInstantiateSingletons()
                    1、获取容器中所有的bean的名称
                    2、通过名称获取bean的定义信息
                    3、根据bean的定义信息判断bean是否是抽象的、单实例的、非懒加载的
                        1、判断是否是factoryBean
                        2、不是工厂bean，利用getBean(beanName)创建对象
                            1、getBean(beanName)-》doGetBean(name, null, null, false)
                                doGetBean里调用Object sharedInstance = getSingleton(beanName);
                                在一级二级三级缓存里获取对象，如果获取不到调用
                                  getSingleton(beanName, () -> {
                                    try {
                                        return createBean(beanName, mbd, args);
                                    }
                                  }方法,在这个方法里先熊一级缓存获取，获取不到就创建
                                getSingleton方法里面在创建bean之前先调用beforeSingletonCreation(beanName)方法将正在创建的bean的name放入
                                singletonsCurrentlyInCreation，正在创建中的beanname；
                                然后调用singletonObject = singletonFactory.getObject()方法正式创建，其实就是调用createBean方法;
                                调用createBean方法前调用了Object bean = resolveBeforeInstantiation(beanName, mbdToUse)
                                试图返回一个代理对象，如果返回了代理对象就return；没有返回代理对象的话就调用doCreateBean正式开始创建对象；
                                doCreateBean方法里调用createBeanInstance创建bean实例，此时还未给属性赋值，给bean实例包装一下之后
                                调用addSingletonFactory(beanName, () -> getEarlyBeanReference(beanName, mbd, bean))方法，给三级缓存
                                singletonFactories赋值，并在registeredSingletons添加已经创建好的bean实例的的名称；
                                对象属性赋值并初始化后就结束对象创建，最后调用addSingleton(beanName, singletonObject)方法
                                将二级缓存，三级缓存相关信息删除，添加至一级缓存，并在registeredSingletons添加已经创建好的bean的名称，
                                并调用afterSingletonCreation方法将singletonsCurrentlyInCreation里的beanname删掉

                            2、Object sharedInstance = getSingleton(beanName);先从缓存中获取是否存在
                                singletonObjects缓存了所有创建好的单实例
                            3、缓存中获取不到，就开始创建bean的过程
                            4、标记当前bean已经被创建
                    4、将创建的单实例bean放到singletonObjects和registeredSingletons中


                    注意几个属性变量
                        singletonObjects 单例对象列表，创建并初始化好的单例对象放在这里面 beanName -> bean实例，map
                        singletonFactories 单例工厂列表，调用对象的构造方法实例化好的对象先放在这个里面，此时还未给属性
                                            赋值，属于半成品，beanName -> beanFactory
                        earlySingletonObjects 循环对象依赖列表，对象在创建之后，进行属性赋值过程中，发现产生了循环依赖，
                                                那么会将对象放入到这个队列，并且从singletonFactories中移除掉。
                        singletonsCurrentlyInCreation 正在创建的单例名称会放到这个队列里
                        registeredSingletons 已经创建好的实例名称列表，这是一个set



spring循环依赖的解决方法
    1、使用了三级缓存处理循环依赖
        这三级缓存分别指：
        singletonFactories ： 单例对象工厂的cache
        earlySingletonObjects ：提前暴光的单例对象的Cache
        singletonObjects：单例对象的cache

    2、过程
        让我们来分析一下“A的某个field或者setter依赖了B的实例对象，同时B的某个field或者setter依赖了A的实例对象”这种循环依
        赖的情况。A首先完成了初始化的第一步，并且将自己提前曝光到singletonFactories中，此时进行初始化的第二步，发现自己依
        赖对象B，此时就尝试去get(B)，发现B还没有被create，所以走create流程，B在初始化第一步的时候发现自己依赖了对象A，于
        是尝试get(A)，尝试一级缓存singletonObjects(肯定没有，因为A还没初始化完全)，尝试二级缓存earlySingletonObjects
        （也没有），尝试三级缓存singletonFactories，由于A通过ObjectFactory将自己提前曝光了，所以B能够通过
        ObjectFactory.getObject拿到A对象(虽然A还没有初始化完全，但是总比没有好呀)，并且将A对象从三级缓存singletonFactories
        移除，同时将A对象放入earlySingletonObjects中；B拿到A对象后顺利完成了初始化阶段
        1、2、3，完全初始化之后将自己放入到一级缓存singletonObjects中。此时返回A中，A此时能拿到B的对象顺利完成自己的初
        始化阶段2、3，最终A也完成了初始化，进去了一级缓存singletonObjects中，而且更加幸运的是，由于B拿到了A的对象引用，
        所以B现在hold住的A对象完成了初始化。

        知道了这个原理时候，肯定就知道为啥Spring不能解决“A的构造方法中依赖了B的实例对象，同时B的构造方法中依赖了A的实例对
        象”这类问题了！因为加入singletonFactories三级缓存的前提是执行了构造器，所以构造器的循环依赖没法解决。


