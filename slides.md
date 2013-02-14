!SLIDE bullets

# Node.js at Betable

* How do I production?

!SLIDE bullets

# Hi, I&#8217;m Richard Crowley

* Equal-opportunity technology hater
* Head of operations at Betable

!SLIDE bullets

# Betable

* Only platform that allows any developer to offer real-money gaming in their apps

!SLIDE bullets

# Node.js because

* V8 is _fast_
* Expresses network services<br>reasonably well

!SLIDE bullets

# Node.js despite

* Callback hell
* Promise hell

!SLIDE bullets

# Pre-production

!SLIDE bullets

# Debian packages

* Deploy by running Puppet
* Easy to vendor dependencies

!SLIDE bullets

# Debian packaging tools

* `fpm`<br><small><a href="https://github.com/jordansissel/fpm">github.com/jordansissel/fpm</a></small>
* `freight`<br><small><a href="https://github.com/rcrowley/freight">github.com/rcrowley/freight</a></small>

!SLIDE bullets

# Git

* Lingua franca for our engineers
* Basis in cryptographic hashes is really convenient for auditability
* `master` is always deployable

!SLIDE bullets

# `git push origin master`

* ...to `git.ops.betable.com`
* `post-receive` pokes Jenkins

!SLIDE bullets

# Jenkins

* We do not use the Git plugin
* &#8220;Execute shell&#8221; build step

!SLIDE bullets

# Jenkins for Node.js

* Clone, if necessary
* Checkout the commit to build
* `NODE_ENV="test" npm install`
* `make test`

!SLIDE bullets

# Jenkins for Node.js

    @@@sh
    git rm .gitignore

    find * -type f |
    git hash-object --stdin-paths -w

    git add .

* Vendor `node_modules`

!SLIDE bullets

# Jenkins for Node.js

    @@@sh
    git write-tree

    git commit-tree "$TREE" \
    -p "$BRANCH_PARENT" -p "$CI_PARENT"

    git update-ref \
    "refs/heads/ci-$BRANCH-latest" \
    "$COMMIT"

    git reset --hard

    git push --force "origin" \
    "$COMMIT:refs/heads/ci-$BRANCH-latest" \
    "$COMMIT:refs/tags/build-$BUILD_NUMBER"

!SLIDE bullets

# <code>deploy <em>service</em> to staging</code>

* The last thing Jenkins does

!SLIDE bullets

# `deploy`

* `flock`(1) to serialize deploys
* Broadcast deploys to Campfire,<br>Graphite, `rsyslog`, and a mailing list
* Then deploys using Git

!SLIDE bullets

# Git, again

    @@@sh
    git update-ref \
    "refs/heads/$BRANCH" "$SHA"

    git push --force \
    "git@$HOST:$APPLICATION.git" "$BRANCH"

* Fast-forwards `staging-latest` to<br>`ci-master-latest` for staging
* Fast-forwards `production-latest` to<br>`staging-latest` for production

!SLIDE bullets

# `post-receive`

* Checks out the pushed commit
* Runs `hooks/post-receive`

!SLIDE bullets

# `hooks/post-receive`

* Manage static files
* Manage load balancer membership
* Restart Upstart service(s)

!SLIDE bullets

# Upstart

* Canonical&#8217;s SysV init replacement
* Meh

!SLIDE bullets

# Upstart because

* Direct parent supervision restarts processes that exit unexpectedly

!SLIDE bullets
.notes Zero-downtime deploys using SCM_RIGHTS from unix(7) still works

# Upstart despite

* Zero-downtime deploys using file descriptor inheritance are impossible

!SLIDE bullets smaller

    @@@sh
    description "betable-id"
    start on runlevel [2345]
    stop on runlevel [!2345]
    respawn
    setuid betable-id
    setgid betable-id
    chdir /usr/local/lib/node_modules/betable-id
    env GRAPHITE_HOST="10.47.108.9"
    env GRAPHITE_PORT="2003"
    env NODE_ENV="staging"
    env NODE_PORT="8020"
    env NSCA="10.47.108.9"
    env STATSD_HOST="10.47.108.9"
    env STATSD_PORT="8125"
    env STATSD_PREFIX="betable-id"
    script
        set -e
        rm -f "/tmp/betable-id.log"
        mkfifo "/tmp/betable-id.log"
        (logger -t"betable-id" <"/tmp/betable-id.log" &)
        exec >"/tmp/betable-id.log" 2>"/tmp/betable-id.log"
        rm "/tmp/betable-id.log"
        exec node "bin/betable-id"
    end script

!SLIDE bullets

# Local Nginx

* Terminates TLS connections
* Routes based on `Host` headers to `node` processes listening on 127.0.0.1

!SLIDE bullets

# Non-local Nginx<br>load balancer

* Terminates TLS connections
* Adds `X-Forwarded-For` header
* Balances load on upstream nodes
* TLS to upstream nodes, too

!SLIDE bullets small

# Load balancer retries

    location / {
      error_page 500 502 503 = @https-retry;
      proxy_intercept_errors on;
      proxy_next_upstream off;
      proxy_pass http://https-upstream;
    }

    location @https-retry {
      proxy_intercept_errors off;
      proxy_next_upstream off;
      proxy_pass http://https-upstream;
      proxy_set_header X-Betable-Retry yes;
    }

* Exactly once to contain cascading failures

!SLIDE bullets

# Everything logs everything

* Request identifier for a poor-man&#8217;s Dapper
* Human-readable and machine-parsable

!SLIDE bullets smaller

    Feb 13 06:26:26 prod02 betable-games: ccbYQHB1xzwqWkjvyKV5i9 > POST /games/REDACTED/bet?access_token=REDACTED HTTP/1.1
    Feb 13 06:26:26 prod02 betable-games: ccbYQHB1xzwqWkjvyKV5i9 > Host: games.internal.betable.com
    Feb 13 06:26:26 prod02 betable-games: ccbYQHB1xzwqWkjvyKV5i9 > Connection: close
    Feb 13 06:26:26 prod02 betable-games: ccbYQHB1xzwqWkjvyKV5i9 > X-Betable-Client-Id: REDACTED
    Feb 13 06:26:26 prod02 betable-games: ccbYQHB1xzwqWkjvyKV5i9 > X-Betable-Request-Id: ccbYQHB1xzwqWkjvyKV5i9
    Feb 13 06:26:26 prod02 betable-games: ccbYQHB1xzwqWkjvyKV5i9 > Authorization: Basic REDACTED (client_id: betable)
    Feb 13 06:26:26 prod02 betable-games: ccbYQHB1xzwqWkjvyKV5i9 > Content-Type: application/json; charset=utf8
    Feb 13 06:26:26 prod02 betable-games: ccbYQHB1xzwqWkjvyKV5i9 > X-Betable-Access-Token: REDACTED
    Feb 13 06:26:26 prod02 betable-games: ccbYQHB1xzwqWkjvyKV5i9 > X-Betable-User-Id: REDACTED
    Feb 13 06:26:26 prod02 betable-games: ccbYQHB1xzwqWkjvyKV5i9 > X-Forwarded-For: 31.222.179.165
    Feb 13 06:26:26 prod02 betable-games: ccbYQHB1xzwqWkjvyKV5i9 > Content-Length: 129
    Feb 13 06:26:26 prod02 betable-games: ccbYQHB1xzwqWkjvyKV5i9 >
    Feb 13 06:26:26 prod02 betable-games: ccbYQHB1xzwqWkjvyKV5i9 > {
    Feb 13 06:26:26 prod02 betable-games: ccbYQHB1xzwqWkjvyKV5i9 >     "currency": "GBP",
    Feb 13 06:26:26 prod02 betable-games: ccbYQHB1xzwqWkjvyKV5i9 >     "economy": "sandbox",
    Feb 13 06:26:26 prod02 betable-games: ccbYQHB1xzwqWkjvyKV5i9 >     "paylines": [
    Feb 13 06:26:26 prod02 betable-games: ccbYQHB1xzwqWkjvyKV5i9 >         [
    Feb 13 06:26:26 prod02 betable-games: ccbYQHB1xzwqWkjvyKV5i9 >             1,
    Feb 13 06:26:26 prod02 betable-games: ccbYQHB1xzwqWkjvyKV5i9 >             1,
    Feb 13 06:26:26 prod02 betable-games: ccbYQHB1xzwqWkjvyKV5i9 >             1
    Feb 13 06:26:26 prod02 betable-games: ccbYQHB1xzwqWkjvyKV5i9 >         ]
    Feb 13 06:26:26 prod02 betable-games: ccbYQHB1xzwqWkjvyKV5i9 >     ],
    Feb 13 06:26:26 prod02 betable-games: ccbYQHB1xzwqWkjvyKV5i9 >     "wager": "0.01",
    Feb 13 06:26:26 prod02 betable-games: ccbYQHB1xzwqWkjvyKV5i9 >     "player_ledger": "REDACTED"
    Feb 13 06:26:26 prod02 betable-games: ccbYQHB1xzwqWkjvyKV5i9 > }

!SLIDE bullets smaller

    ccbYQHB1xzwqWkjvyKV5i9 > POST /games/REDACTED/bet?access_token=REDACTED HTTP/1.1
    ccbYQHB1xzwqWkjvyKV5i9 > Host: games.internal.betable.com
    ccbYQHB1xzwqWkjvyKV5i9 > Connection: close
    ccbYQHB1xzwqWkjvyKV5i9 > X-Betable-Client-Id: REDACTED
    ccbYQHB1xzwqWkjvyKV5i9 > X-Betable-Request-Id: ccbYQHB1xzwqWkjvyKV5i9
    ccbYQHB1xzwqWkjvyKV5i9 > Authorization: Basic REDACTED (client_id: betable)
    ccbYQHB1xzwqWkjvyKV5i9 > Content-Type: application/json; charset=utf8
    ccbYQHB1xzwqWkjvyKV5i9 > X-Betable-Access-Token: REDACTED
    ccbYQHB1xzwqWkjvyKV5i9 > X-Betable-User-Id: REDACTED
    ccbYQHB1xzwqWkjvyKV5i9 > X-Forwarded-For: 31.222.179.165
    ccbYQHB1xzwqWkjvyKV5i9 > Content-Length: 129
    ccbYQHB1xzwqWkjvyKV5i9 >
    ccbYQHB1xzwqWkjvyKV5i9 > {
    ccbYQHB1xzwqWkjvyKV5i9 >     "currency": "GBP",
    ccbYQHB1xzwqWkjvyKV5i9 >     "economy": "sandbox",
    ccbYQHB1xzwqWkjvyKV5i9 >     "paylines": [
    ccbYQHB1xzwqWkjvyKV5i9 >         [
    ccbYQHB1xzwqWkjvyKV5i9 >             1,
    ccbYQHB1xzwqWkjvyKV5i9 >             1,
    ccbYQHB1xzwqWkjvyKV5i9 >             1
    ccbYQHB1xzwqWkjvyKV5i9 >         ]
    ccbYQHB1xzwqWkjvyKV5i9 >     ],
    ccbYQHB1xzwqWkjvyKV5i9 >     "wager": "0.01",
    ccbYQHB1xzwqWkjvyKV5i9 >     "player_ledger": "REDACTED"
    ccbYQHB1xzwqWkjvyKV5i9 > }

!SLIDE bullets smaller

    > POST /games/REDACTED/bet?access_token=REDACTED HTTP/1.1
    > Host: games.internal.betable.com
    > Connection: close
    > X-Betable-Client-Id: REDACTED
    > X-Betable-Request-Id: ccbYQHB1xzwqWkjvyKV5i9
    > Authorization: Basic REDACTED (client_id: betable)
    > Content-Type: application/json; charset=utf8
    > X-Betable-Access-Token: REDACTED
    > X-Betable-User-Id: REDACTED
    > X-Forwarded-For: 31.222.179.165
    > Content-Length: 129
    >
    > {
    >     "currency": "GBP",
    >     "economy": "sandbox",
    >     "paylines": [
    >         [
    >             1,
    >             1,
    >             1
    >         ]
    >     ],
    >     "wager": "0.01",
    >     "player_ledger": "REDACTED"
    > }

!SLIDE bullets smaller

    < HTTP/1.1 201 Created
    <
    < {
    <     "window": [
    <         [
    <             "smalls",
    <             "smalls",
    <             "smalls"
    <         ],
    <         [
    <             "biggie",
    <             "biggie",
    <             "smalls"
    <         ],
    <         [
    <             "smalls",
    <             "smalls",
    <             "smalls"
    <         ]
    <     ],
    <     "outcomes": [
    <         {
    <             "outcome": "lose",
    <             "payline": [
    <                 1,

!SLIDE bullets smaller

    <                 1,
    <                 1
    <             ],
    <             "symbols": [
    <                 "biggie",
    <                 "biggie",
    <                 "smalls"
    <             ],
    <             "payout": "0.00",
    <             "credits": {},
    <             "progressives": {}
    <         }
    <     ],
    <     "stops": [
    <         1,
    <         2,
    <         1
    <     ],
    <     "payout": "0.00",
    <     "credits": {},
    <     "progressives": {},
    <     "currency": "GBP"
    < }
      164ms

!SLIDE bullets small

# `logger` Connect middleware

    @@@javascript
    function logger(request, response, next) {
        var chunks = []
          , end = response.end
          , write = response.write
        response.write = function (chunk) {
            chunks.push(chunk)
            write.apply(response, arguments)
        }
        response.end = function (chunk) {
            end.apply(response, arguments)
            var log = []

            // ...

            process.stdout.write(log.join('\n'))
        }
    }

!SLIDE bullets

# `logger` Connect middleware

* Prefix lines with request identifier
* Redact sensitive information
* Stringify request and response bodies
* Time to first byte

!SLIDE bullets

# Upstart, again

* `node` standard output and standard error<br>redirected to a named pipe
* `logger`(1) standard input<br>redirected from the named pipe

!SLIDE bullets

# `rsyslog`(8)

* Forward log entries to `log.ops.betable.com`
* We use the reliable transport called RELP

!SLIDE bullets

# Near-realtime log processing

* Call attention to HTTP 500 responses
* Extract and forward metrics to Graphite

!SLIDE bullets

# Logstash

* Removed because ElasticSearch<br>is a mess operationally
* Would like it back
* Will not be using native ElasticSearch clients or RabbitMQ when we bring it back

!SLIDE bullets

# `statsd`

* Additional metrics come from the code
* Finer-grained metrics are possible with context available in the code
* `statsd` aggregates datagrams into Graphite

!SLIDE bullets

# Puppet

* Configuration management
* Peer discovery
* Emergent firewall rules
* Deployed via Git, too

!SLIDE bullets

# All the things

* Git<br>Jenkins<br>Upstart<br>Nginx<br>`logger`(1)<br>`rsyslog`(8)<br>Logstash<br>`statsd`<br>Graphite<br>Puppet

!SLIDE bullets

# You know you want to work at Betable

* Almost as much as you knew<br>this slide was coming
* <richard@betable.com>

!SLIDE bullets

# Thank you

* <a href="http://rcrowley.org/talks/nodejs-2013-02-19/">rcrowley.org/talks/nodejs-2013-02-19/</a>
* <r@rcrowley.org> or <a href="https://twitter.com/rcrowley">@rcrowley</a>
