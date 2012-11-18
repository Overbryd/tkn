# encoding: utf-8

slide <<-EOS, :center
  \e[1mStateful Application Server\e[0m


  Lukas Rieder
  @Overbryd

  RuPy
  Brno, Nov 2012
EOS

# I am talkin about a stateful application server.
# This thing is different from stateless where
# an "infinitely" scalable application server tier
# talks to some kind of database.

# Stateful servers, in my opinion, are not infinitely scalable.
# They have more constraints, and are not as flexible to requirement changes.
# But they give an insane opportunity to achieve very high throughput.

# Why do we do all this?

section "Requirements of our Game" do

  # This is a browser game, so people's actions are tiny but frequent.

  # Image our main target, a 40 year old women who as just discovered Facebook.
  # She has a virtual town where she can build her empire, harvest from trees,
  # collect taxes, and so on.

  slide <<-EOS, :center
    \e[1mIntense but short lived sessions\e[0m

    Many small actions happen very frequently per session.
  EOS

  # She plays during work, obviously, so sessions tend to be short.

  slide <<-EOS, :center
    \e[1mIntense but short lived sessions\e[0m

    Users come and go within 5 minutes.
  EOS

  # There is a lot of 40 year old women just discovering Facebook.

  slide <<-EOS, :center
    \e[1mScale\e[0m

    We plan for about 1 Million
    daily active users (DAU).
  EOS

  # But this is not the first social game Wooga is building.

  slide <<-EOS, :center
    \e[1mScale\e[0m

    Looking at other games, the amount of
    simultaneous users is predictable.
  EOS

  # We look at our games that are live, and look at the growth.

  slide <<-EOS, :center
    \e[1mScale\e[0m

    The load we can expect for
    the application lifetime is finite.
  EOS

  # Zero downtime deployments
  slide <<-EOS, :center
  
  EOS

  # Good Night's Sleep is kind of a weird requirement.
  # Me and my colleague have to think about maintainability a lot.

  slide <<-EOS, :center
    \e[1mGood Night's Sleep\e[0m

    We as developers are responsible
    for the whole system.
  EOS

  slide <<-EOS, :center
    \e[1mGood Night's Sleep\e[0m

    If monitoring triggers an alarm,
    there is a call chain.
  EOS

  # And on the end of the call chain, there is the CTO.
  # If we screw up, and we don't respond we in TROUBLE!

  slide <<-EOS, :center
    \e[1mGood Night's Sleep\e[0m

    On the end of the chain,
    is the CTO.
  EOS

end

section "Good Night's Sleep Prayer™" do
    slide <<-EOS, :block
      \e[1mGood Night's Sleep Prayer™\e[0m


      Dear Science,

      we want to understand our system,

      and to achieve a good understanding,

      let us grow the system step by step,

      let the spirit of Rich Hickey live through us,

      to our application.
    EOS
end

# Now you know what we are up to.
# We build a very good social game, for more than 1 MIO DAU who are mostly women in the fourties. We do that for your mother, most probably.

# Next up is how we solved our problems.
# Let's meet those requirements!

section "Meeting the requirements" do

  # Remember intense but short lived sessions?
  # We had two particular ideas I want to share with you.

  # If you don't have a database roundtrip, you save time.

  # If you batch many almost atomic updates,
  # you'll get better throughput if they appear in a large quantity.
  slide <<-EOS, :center
    \e[1mIntense but short lived sessions\e[0m

      "Many small updates are done
       faster when done in memory."

      "Many small actions are sent in batches."
  EOS

  # Here you see a list of actions with their parameters

  slide <<-EOS, :block
    Almost every click in the client is an action
    that must be validated and persistet.

    quest/start_sequence {:quest_id=>"mentor001"}
    upgrade/whack {:y=>48, :x=>57}
    upgrade/whack {:y=>48, :x=>57}
    upgrade/whack {:y=>48, :x=>57}
    upgrade/finish {:y=>48, :x=>57}
    user/level_up {:level=>2}
  EOS

  # In this example, we will batch those 6 actions in one HTTP request

  slide <<-EOS, :block
    To avoid HTTP overhead, those actions are batched

    1 HTTP request = 6 actions
  EOS

  # Our batching is dead simple. Batch execute is a regular command,
  # As parameters it accepts an array of other command specifications.

  # Very straightforward, just a JSON body. Could be MessagePack.

  slide <<-EOS, :code
    \e[1mPOST\e[0m /123/batch/execute

    [
      { "name": "\e[1mquest/start_sequence\e[0m", "params": { "quest_id": "mentor001" } },
      { "name": "\e[1mupgrade/whack\e[0m", "params": { "x": 48, "y": 57 } },
      { "name": "\e[1mupgrade/whack\e[0m", "params": { "x": 48, "y": 57 } },
      { "name": "\e[1mupgrade/whack\e[0m", "params": { "x": 48, "y": 57 } },
      { "name": "\e[1mupgrade/finish\e[0m", "params": { "x": 48, "y": 57 } },
      { "name": "\e[1muser/level_up\e[0m", "params": { "level": 2 } }
    ]
  EOS

  # Let's step deeper into our codebase.
  # We use the Cuba Rack micro framework,
  # here we match for a POST Batch execute request.

  slide <<-EOS, :code
    # game_x.rb

    class GameX < Cuba

      \e[1mon\e[0m post do

        \e[1mon\e[0m ":session_id/batch/execute" do |session_id|
          Session.with(session_id) do |session|
            \e[1meach_batched\e[0m do |name, method, params|
              command = AbstractCommand.by_name(name).new(session, params)
              command.send(method)
            end
          end
          render_json
        end

        # ...
      end

      # ...
    end
  EOS

  # Now other commands are very nice to read.
  # We aim for readable idiomatic Ruby code. Avoiding magic.

  slide <<-EOS, :code
    # commands/quest_command.rb
    class QuestCommand < AbstractCommand

      def start_sequence
        session.quests.start(required_param(:quest_id))
        session.touch
      end

      # ...

    private

      def quest
        @quest ||= session.quests[id] or raise(Invalid, "quest not yet started: \#{id}")
      end

    end
  EOS

  # In this example, the player clicks a building to upgrade a house to another level.
  # Commands are basically just like Controllers combining various models.

  slide <<-EOS, :code
    # commands/upgrade_command.rb
    class UpgradeCommand < AbstractCommand

      def whack
        session.using_energy_or_help(helper_id, x, y) do
          contract.whack
        end
        session.touch
      end

      # ...

    private

      def contract
        item.upgrade or raise(Invalid, "has no upgrade contract")
      end

    end
  EOS

  # This gives us a very straightforward well structured system.
  # The User Command is a very good example, how one action
  # consists out of many micro updates on the Gamestate.

  slide <<-EOS, :code
    # commands/user_command.rb
    class UserCommand < AbstractCommand

      def level_up
        raise Invalid, "cannot skip level \#{session.level + 1}" \\
          unless level == session.level + 1
        raise Invalid, "not enough xp" unless max_level >= level
        session.level = level
        session.resources.plus(rewards)
        session.energy.refill
        session.send_broadcast
        session.touch
      end

      # ...

    end
  EOS

  # The next requirement we talked about is Scale.

  # The idea we had, was simply this. Today this is absoultely valid,
  # since memory is cheap.

  slide <<-EOS, :center
    \e[1mScale\e[0m

    "As long as all active Sessions
     fit into memory, we are good."
  EOS

  # To meet this requirement, first we went shopping.
  # At Wooga, every team can decide for their own
  # hosting solution. This allows us to tailor our whole system.

  # In our case, we rented a bunch of bigger machines from Serverloft.

  slide <<-EOS, :block
    \e[1mLets go shopping\e[0m aka Scale up

    32 cores
    32 GB RAM
    SSDs
    2x GBit network cards
    Good peering and a strong uplink
    CDN backed
  EOS

  # But all those sessions won't fit into one single machine.
  # That is why we have to split sessions.

  slide <<-EOS, :center
    \e[1mScale out\e[0m

    Distributing sessions across multiple servers.

    We call them shards.
  EOS

  # This is generally dangerous.
  # When building a stateful application server, one very important aspect is,
  # that one session is always in one place.

  # If you are creative, you can make yourself a calendar,
  # each day is a different race condition that might appear around
  # the session handling.

  slide <<-EOS, :center
    \e[1mScale out\e[0m

    The have found a magic formula,
    that holds together everything!
  EOS

  # Statistically a modulo operation evens out eventually.
  # This simple rule, allows us to share this everywhere.

  slide <<-EOS, :center
    \e[1msession_id % number_of_shards = shard\e[0m

    566192342 % 2 = 0
  EOS

  # But of course, there are trade offs.

  # One in particular is the landing page request from Facebook.
  # Facebook will not talk to one specific shard.

  # That forces us to deliver a static landing page,
  # servable from every application server.

  slide <<-EOS, :block
    \e[1mScale out\e[0m

    Landing page requests go to \e[1mgx.wooga.com\e[0m.
    DNS round robin takes care of 'balancing' them.

    All further requests go directly to their shard.
    566192342  % 2 => \e[1mgx-0.wooga.com\e[0m
    1220032045 % 2 => \e[1mgx-1.wooga.com\e[0m
  EOS

  # The other is Rebalancing.
  # A new deployment with a changed cluster size,
  # does not necessarely knows where to locate a previous hot session.

  # We have to shutdown the whole cluster.

  slide <<-EOS, :block
    \e[1mScale out\e[0m

    We take some tradeoffs for the sake of simplicity.

    Rebalancing requires to shutdown the whole cluster.

    We plan ahead (russian style) and
    aim to not rebalance more than once a year,
    until DAU peaks.
  EOS

  # This leads us to Planning.
  # In order to not be surprised by known problems,
  # we plan ahead, pulling together knowledge from other games
  # and our own live data.

  slide <<-EOS, :block
    \e[1mPlanning\e[0m

    We do simple approximations,
    and adjust those with live data from time to time.

    For example: \e[1mtime_budget = cores * shards\e[0m
  EOS

  slide <<-EOS, :block
    \e[1mPlanning\e[0m

    If an average transaction takes \e[1m20ms\e[0m,

    with \e[1m32\e[0m cores per shard and \e[1m4\e[0m shards,

    \e[1m6400\e[0m transactions per second is our limit.
  EOS

  slide <<-EOS, :block
    \e[1mPlanning\e[0m

    If \e[1m1 Million DAU\e[0m generates a load of \e[1m4000req/s\e[0m,

    and our most expensive transaction takes \e[1m100ms\e[0m,

    but those make only a \e[1m1/4\e[0m of all calls,

    the maximum for each other call is ~ \e[1m9ms\e[0m.
  EOS

end

# The last section in this talk will go down another path.
# I want to share our concurrency problem, and how we distribute our work load.

# You could also ask, How to make Programming an adrenaline fueled exciting job?

section "The Concurrency Model" do
  slide <<-EOS, :center
    How to make Programming

    an \e[1madrenaline fueled exciting\e[0m job?
  EOS

  # You can drinks lots of coffee of course!

  slide <<-EOS, :center
    \e[1mCoffee!\e[0m
  EOS

  # But we don't drink so much coffee,
  # we write multi-threaded code!

  # Basically threading is the gateway drug,
  # to more sophisticated forms of concurrency.

  slide <<-EOS, :center
    Threads!
  EOS

  # What is the nature of Threads?
  # Different to green processes from Erlang,
  # where the Erlang VM supports thousands of processes at the same time!

  # Too many threads will give you a painful scheduling overhead.
  # Just be aware of the number of threads you are spinning off.

  # Spinning threads up and down constantly will also be a pain.
  # So if you start threads, you usually use some kind of Pool.

  # Threads share memory within one process.

  slide <<-EOS, :center
    \e[1mThreads\e[0m

    They are not as lightweight as perceived,
    but good for keeping them around.
  EOS

  # That is why we have choosen JRuby as our Ruby platform.
  # It just makes working with threads a bliss!

  # If you are interested, have a peek into java.util.concurrent.
  # There are all sorts of Atomic value holders, threadsafe data structures,
  # Thread pools with all sorts of magic variants.

  slide <<-EOS, :center
    \e[1mThreads\e[0m

    JRuby makes working with Threads a bliss.

    \e[1mjava.util.concurrent\e[0m
  EOS

  # What are the threads we are keeping around?

  # Remember that all of those share the same memory,
  # shared resources like all the Gamestates must be made threadsafe.

  slide <<-EOS, :block
    \e[1mThreads\e[0m

    Tomcat
    1 acceptor thread
    30 worker threads

    Application
    1 ticker thread,
      shuts down inactive sessions
    1 broadcast thread,
      tells other shards about updates
  EOS

  # This shows our main Session model, responsible of
  # holding all active sessions in memory.

  # In self.get you can see some required code,
  # to make the use of Concurrent Hashmap threadsafe.

  # Unless we get a session from the Hashmap,
  # we create a new session,
  # but since if some other thread could have created one in the meantime,
  # we again try to put our newly created session back.
  # If we successfully write the session back to the Hashmap,
  # put_if_absent will return nil, and we continue to use our newly created session.
  # Otherwise we will use the session created by the other thread.

  slide <<-EOS, :code
    # models/session.rb

    require "java"
    import  "java.util.concurrent.ConcurrentHashMap"

    class Session

      def self.current
        @current ||= ConcurrentHashMap.new
      end

      def self.get(id)
        unless session = current.get(id)
          new_session = create(id)
          unless session = current.put_if_absent(id, new_session)
            session = new_session
          end
        end
        session
      end

      # ...

    end
  EOS

  # That was the code to make the Session storage threadsafe,
  # now how to make operations on one session safe?

  # We can simply use a lock. There are very little
  # concurrent modifications per session,
  # are expected to be subsequent.

  # The amount of lock wait time will be around zero.

  slide <<-EOS, :code
    # models/session.rb

    class Session

      # Blocking but thread-safe access to a session
      def self.with(id)
        get(id).lock.synchronize { yield session }
      end

      attr_reader :id, :lock

      def initialize(id, data)
        @id = id
        @data = data
        @lock = Mutex.new
      end

      # ...
    end
  EOS

  # The last but most tricky requirement is zero downtime deployments.
  # What do you do with active sessions?
  # You cannot just shutdown the old instance and kill all active sessions.

  slide <<-EOS, :center
    \e[1mZero downtime deployments\e[0m

    "Keep on rolling forward."
  EOS

  slide <<-EOS, :block
    \e[1mDeployment process\e[0m

    We tarball the whole release candidate, including assets and client,

    Rsync that to all shards,

    Spin off a new JVM instance on the next free port,

    Tell the new instance about the current port,

    Wait for first successful response (JVM makes us drink more coffee),

    Rewrite the nginx configuration to point to the new port,

    Reload nginx configuration. Done.
  EOS

  slide <<-EOS, :block
    \e[1mSession handover\e[0m

    Any request hits the new instance,

    the new instance will ask his Session manager,

    if nothing found, ask the previous instance,

    if nothing found there, lets just create a fresh session.
  EOS

  slide <<-EOS, :code
    # provisioning/nginx/gamex.conf
    # ...

      location / {
        if (-f $document_root/maintenance.html) {
          return 503;
        }
        rewrite "^(.*)\.[0-9a-f]{4}\.(.*)$" $1.$2 break;
        if (!-f $request_filename) {
          proxy_pass http://127.0.0.1:3999;
        }
      }

      # ...
  EOS

  slide <<-EOS, :code  
    # deployment/start.sh
    # ...

    sed -i -e "s/$new_port/$port/" /etc/nginx/gamex.conf

    # Another process watches this files
    # and reloads nginx on changes.
    # ...
  EOS

  slide <<-EOS, :block
    \e[1mInstance lifecycle\e[0m
  
    One instance is aware of its previous instances,

    a previous instance is aware when not serving any more,

    and is therefore able to kill itself after being emptied.
  EOS

end

# This all the juicy details I have chosen to show to you today.
# There is way more to tell, but I am afraid this would fill another three talks.

# I want to give you some inspiration,
# based on what I showed to you this presentation.

section "Wrapping up" do

  # Just explore and play around with Concurrency!
  # It is actually a lot of fun, and there is a lot of things,
  # in the past and present, just waiting to be discovered.

  # It will probably give your programming carreer another 10 years,
  # before you turn into a Project Manager.

  slide <<-EOS, :center
    \e[1mExplore\e[0m and \e[1mplay\e[0m around with \e[1mConcurrency\e[0m.

    Processes, \e[1mThreads\e[0m, Synchronisation,
    Actor Model, Software Transactional Memory.
  EOS

  # Look at your language, look at your knowledge.
  # What can you do today?

  # What can you do to improve the situation?

  slide <<-EOS, :center
    How can you achieve
    
    \e[1mconcurrency\e[0m, \e[1mproductivity\e[0m and \e[1msimplicity\e[0m

    with the tools \e[1myou know\e[0m today?
  EOS

  # Even if you have an unpredictable, vague problem
  # start puzzling together a big picture.

  slide <<-EOS, :center
    \e[1mEnable yourself\e[0m to plan ahead.

    A \e[1mplan helps\e[0m to stay focused,
    and \e[1menables better decision\e[0m making.
  EOS

end

slide `jp2a --clear --width=35 --colors --term-fit --invert wooga.jpg` << <<-EOS, :center, 0.05
  Thanks!

  @Overbryd
EOS
