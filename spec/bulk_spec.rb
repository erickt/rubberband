require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "bulk ops" do
  before(:all) do
    @index = 'first-' + Time.now.to_i.to_s
    @client = ElasticSearch.new('http://127.0.0.1:9200', :index => @index, :type => "tweet")
  end

  after(:all) do
    @client.delete_index(@index)
    sleep(1)
  end

  it "should index documents in bulk" do
    @client.bulk do |c|
      c.index({:foo => 'bar'}, :id => '1')
      c.index({:foo => 'baz'}, :id => '2')
    end
    @client.bulk do
      @client.index({:socks => 'stripey'}, :id => '3')
      @client.index({:socks => 'argyle'}, :id => '4')
    end
    @client.refresh

    @client.get("1").foo.should == "bar"
    @client.get("2").foo.should == "baz"
    @client.get("3").socks.should == "stripey"
    @client.get("4").socks.should == "argyle"
  end

  it "should allow nested bulk calls" do
    @client.bulk do |c|
      c.index({:foo => 'bar'}, :id => '11')
      c.index({:foo => 'baz'}, :id => '12')
      @client.bulk do
        @client.index({:socks => 'stripey'}, :id => '13')
        @client.index({:socks => 'argyle'}, :id => '14')
      end
    end
    @client.refresh

    @client.get("11").foo.should == "bar"
    @client.get("12").foo.should == "baz"
    @client.get("13").socks.should == "stripey"
    @client.get("14").socks.should == "argyle"
  end

  it "should take options" do
    @client.bulk do |c|
      c.index({:foo => 'bar'}, :id => '1', :_routing => '1', :_parent => '1')
      #TODO better way to test this?
      meta = c.instance_variable_get('@batch').detect { |b| b.has_key?(:index) }
      meta[:index].should include(:_routing => '1')
      meta[:index].should include(:_parent => '1')
    end
  end
end
