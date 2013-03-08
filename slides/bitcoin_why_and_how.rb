@default_slide_time = 0
@default_format = :center

section "JRuby and BitcoinJ" do

  slide <<-EOS, :code
    # require bitcoinj
    require File.expand_path("../bitcoinj-latest.jar", __FILE__)
    require File.expand_path("../bitcoinj-tools-latest.jar", __FILE__)
    module BitcoinJ
      include_package "com.google.bitcoin.core"
      import com.google.bitcoin.discovery.DnsDiscovery
      import com.google.bitcoin.store.DiskBlockStore
    end
  EOS

  slide <<-EOS, :code
    # require necessary java stuff
    require "java"
    module J
      import java.io.File
      import java.net.InetAddress
      import java.util.concurrent.TimeUnit
    end
  EOS

  slide <<-EOS, :code
    # initialize core classes
    def initialize(file)
      @network = BitcoinJ::NetworkParameters.prod_net
      begin
        @wallet = BitcoinJ::Wallet.load_from_file(J::File.new(file))
      rescue java.io.FileNotFoundException
        @wallet = BitcoinJ::Wallet.new(@network)
        @wallet.add_key BitcoinJ::ECKey.new
        @wallet.save_to_file(file)
      end
      @block_store = BitcoinJ::DiskBlockStore.new(@network, J::File.new("test.blockchain"))
      @chain = BitcoinJ::BlockChain.new(@network, @wallet, @block_store)
      @peer_group = BitcoinJ::PeerGroup.new(@network, @chain)
    end
  EOS

  slide <<-EOS, :code
    # connect to the network
    @peer_group.add_peer_discovery(BitcoinJ::DnsDiscovery.new(@network))
    @peer_group.add_wallet(@wallet)
    @peer_group.start_and_wait
  EOS

  slide <<-EOS, :code
    # update the block chain
    @peer_group.download_block_chain
    @wallet.save_to_file(J::File.new("test.wallet"))
  EOS

  slide "... well ..."
  slide "Java code        \"yay\""
end

section "฿itcoins" do
  slide "Why? Why, Bitcoins?"
  slide "Why are they any different from #{"Magic Card Trading".underline}?"

  slide <<-EOS
  The first #{"digital currency".underline} that

  solves the #{"double spending problem".underline}!
  EOS

  slide "double spending ..what?"

  slide "Common solutions use #{"centralization".underline}"

  slide "Centralized solutions inherit #{"single point of failures".underline}"

  slide "PayPal, Credit cards, ..."

  slide "They are prone to fail in means of #{"trust".underline}"

  slide "They are prone to fail for #{"technical".underline} reasons"

  slide "They are insufficient for the internet!"
end

section "A better currency" do

  slide <<-EOS, :block
    I transfer 2฿ to Florian

    I create a message (transaction) with Florians public key

    The transaction is signed with my private key.

    Broadcasting the transaction tells other nodes about the new owner.

    Everybody can verify the authenticity due to my signature.
  EOS

  slide <<-EOS, :block
    Eventually the transaction will be stored in the block chain.

    The deeper my transaction is buried in the block chain

    the more confidence it gets.
  EOS

  slide <<-EOS
    < past            future >

    B0 <- B1 <- B2 <- B3 <- B4
  EOS

  slide <<-EOS, :block
    SIG = #{"SIG_B4".underline}  #{"Nonce, Timestamp".underline}  #{"Merkle Root".underline}


       _____     <- Merkle Root
    _____ _____
    #{"T1 T2".underline} #{"T3 T4".underline}
  EOS

  slide <<-EOS, :block
    The first part of the SIGnature must be smaller

    than the current difficulty set by the network.
  EOS

  slide <<-EOS, :block
    #{"http://blockchain.info/block-index/355090".underline}

          4367876 to BITS
          v
    SIG = 00000000000002d28433a5a79c357a328d6e11994f1c16d789c9934a2b1c2f2f
  EOS

  slide <<-EOS, :block
    Decentralized

    Anonymous

    Open Source
  EOS

  slide <<-EOS
    Bitcoin needs people like you

    Become part of it, hack it, build upon it!

    Questions? No? Let's do it!
  EOS
end

section "
thanks,
Lukas 'Overbryd' Rieder
" do

end