
Docker build and run with a 1-core, 50% host cpu limit.
```
$ docker-compose build
$ docker run --rm -it --cpus=".5" --cpuset-cpus=1 -p 8080:8080 puma_web:latest
```

Run the perf test. We saturate puma's 16 threads.
```
$ ab -n 10000 -c 24 http://localhost:8080/

Requests per second:    478.61 [#/sec] (mean)
Time per request:       50.145 [ms] (mean)
Time per request:       2.089 [ms] (mean, across all concurrent requests)
Transfer rate:          72.91 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    0   1.7      0     171
Processing:     3   50  35.6     27     235
Waiting:        3   50  35.5     27     235
Total:          4   50  35.6     27     235

Percentage of the requests served within a certain time (ms)
  50%     27
  66%     73
  75%     74
  80%     75
  90%     77
  95%     83
  98%    181
  99%    198
 100%    235 (longest request)
```
