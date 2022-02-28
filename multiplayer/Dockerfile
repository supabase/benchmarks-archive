from grafana/k6:latest

COPY k6/latency.js .

ENTRYPOINT [ "k6", "run", "--summary-trend-stats", "min,avg,med,p(99),p(99.9),p(95),p(90),p(50),p(0.1),p(0.01),max,count", "loader.js" ]