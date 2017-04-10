erl +K true -smp enable  -pa lib/ebin -s zggame -mnesia dir "\"lib/spool\"" -sname test@qa
#+sbt db +sub true +S 4:4
# -smp enable  多核
# +sbt db：讲调度器绑定到具体的CPU核心上，减少核之间的切换
# +K true  epoll
# +P 1024000 最大进程数
# +Q 65536 最大port数
# +S Schedulers:SchedulerOnline 最大可用调度器数量(默认和核心数相同)和具体使用调度器数量
# +swt low ；提高调度器唤醒灵敏度，避免长时间运行睡死问题
# +sub true  提高调度器利用率(默认是负载均衡，降低能耗)