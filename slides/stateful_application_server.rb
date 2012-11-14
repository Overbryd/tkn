# encoding: utf-8

slide <<-EOS, :center
  \e[1mStateful Application Server\e[0m


  Lukas Rieder
  @Overbryd

  Ruby User Group Berlin
  Nov 2012
EOS

section "Requirements of our Game" do

  slide <<-EOS, :block
    Intense but short lived sessions

    ➩ Many small actions are being
      made frequently per session
  EOS

  slide <<-EOS, :block
    Scale

    ➩ We plan for about 1 Million DAU
  EOS

  slide <<-EOS, :block
    Responsiveness

    ➩ Fast loading
    ➩ As few blocking requests as possible
    ➩ Throughput is key
  EOS

  slide <<-EOS, :block
    Good Night's Sleep™

    ➩ Simple fault tolerant system
    ➩ Idiomatic Ruby code
  EOS

end

section "Meeting the requirements" do

  slide <<-EOS, :block
    Intense but short lived sessions
    
      "Many small updates are done
       faster when done in memory."
    
      "Many small actions are sent in batches."
  EOS

  slide <<-EOS, :block
    Client produces lots of actions
    that must be validated and persistet

      quest/start_sequence {:quest_id=>"mentor001"}
      upgrade/whack {:y=>48, :x=>57}
      upgrade/whack {:y=>48, :x=>57}
      upgrade/whack {:y=>48, :x=>57}
      upgrade/finish {:y=>48, :x=>57}
      user/level_up {:level=>2}
  EOS

  slide <<-EOS, :block
    To avoid HTTP overhead, those actions are batched
    
    1 HTTP request = 6 actions
    
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

  slide <<-EOS, :code
    # game_x.rb

    class GameX < Cuba
      
      \e[1mon\e[0m post do
        
        \e[1mon\e[0m ":session_id/batch/execute" do |session_id|
          Session.with(session_id) do |session|
            raise session.last_error if session.last_error
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
        item.upgrade || raise(Invalid, "has no upgrade contract")
      end

    end
  EOS

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

  slide <<-EOS, :block
    Scale

      "As long as all active Sessions fit into memory, we are good."
  EOS

  slide <<-EOS, :block
    Scaling up

      32 cores
      32 GB RAM
      SSDs
      2x GBit network cards
  EOS

  slide <<-EOS, :block
    Scaling out

      Distributing sessions across multiple servers (shards).
  EOS

  slide <<-EOS, :block
    Scaling out

      The magic formula, that holds together everything:

      \e[1mSESSION_ID % NUMBER_OF_SHARDS = SHARD\e[0m

      566192342 % 2 = 0
  EOS

  slide <<-EOS, :block
    Scaling out

      Landing page requests go to \e[1mgx.wooga.com\e[0m.
      DNS round robin takes care of 'balancing' them.

      All further requests go directly to their shard.
      566192342  % 2 => \e[1mgx-0.wooga.com\e[0m
      1220032045 % 2 => \e[1mgx-1.wooga.com\e[0m
  EOS

  slide <<-EOS, :block
    Scaling out

      Rebalancing requires to shutdown the whole cluster.
      We plan ahead and aim to not rebalance more than once a year.
  EOS

end

section "The Concurrency Model" do
  slide <<-EOS, :center
    Threads!
  EOS

  slide <<-EOS, :block
    Threads!

      They are not as lightweight as perceived
      But good for keeping them around
  EOS

  slide <<-EOS, :block
    Threads!

      Sharing state makes programming so much more exciting!!
  EOS

  slide <<-EOS, :block
    Threads!

      JRuby makes working with Threads a bliss.
    
      \e[1mjava.util.concurrent\e[0m
  EOS

  slide <<-EOS, :block
    Threads!

    Tomcat
    1 acceptor thread
    30 worker threads
    
    Application
    1 ticker thread for shutting down inactive sessions
    1 broadcast thread for telling other shards about updates
  EOS

  slide <<-EOS, :code
    # models/session.rb

    require "json"
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

end

section "The End" do; end
