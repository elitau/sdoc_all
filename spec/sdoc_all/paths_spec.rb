require File.dirname(__FILE__) + '/../spec_helper.rb'

describe SdocAll::Paths do
  it "should determine common path part" do
    paths = %w(/aaa/bbb/ccc/ddd/a.rb /aaa/bbb/ccc/ddd/b.rb /aaa/bbb/ccc/readme).map{ |path| Pathname.new(path) }
    SdocAll::Paths.common_path(paths).should == Pathname.new('/aaa/bbb')
  end

  it "should add task for string config" do
    @roots = {}
    [:a, :b, :c].each do |sym|
      @roots[sym] = mock(sym, :expand_path => mock("#{sym}_exp".to_sym, :exist? => true, :relative_path_from => "lala/#{sym}_exp"))
      Pathname.should_receive(:new).with("#{sym}").and_return(@roots[sym])
      SdocAll::Base.should_receive(:add_task).with(:doc_path => "paths.lala.#{sym}_exp", :src_path => @roots[sym].expand_path, :title => "paths: lala/#{sym}_exp")
    end
    SdocAll::Paths.should_receive(:common_path).with(@roots.values_at(:a, :b, :c).map(&:expand_path)).and_return('/common')

    File.should_receive(:expand_path).with('*').and_return('/common/lala/*')
    Dir.should_receive(:[]).with('/common/lala/*').and_return(['a', 'b', 'c'])
    SdocAll::Paths.new('*').add_tasks
  end

  it "should add task for array of strings config" do
    @roots = {}
    [:a, :b, :d, :e].each do |sym|
      @roots[sym] = mock(sym, :expand_path => mock("#{sym}_exp".to_sym, :exist? => true, :relative_path_from => "lala/#{sym}_exp"))
      Pathname.should_receive(:new).with("#{sym}").and_return(@roots[sym])
      SdocAll::Base.should_receive(:add_task).with(:doc_path => "paths.lala.#{sym}_exp", :src_path => @roots[sym].expand_path, :title => "paths: lala/#{sym}_exp")
    end
    SdocAll::Paths.should_receive(:common_path).with(@roots.values_at(:a, :b, :d, :e).map(&:expand_path)).and_return('/common')

    File.should_receive(:expand_path).with('*').and_return('/common/lala/*')
    File.should_receive(:expand_path).with('**').and_return('/common/common/lala/*')
    Dir.should_receive(:[]).with('/common/lala/*').and_return(['a', 'b'])
    Dir.should_receive(:[]).with('/common/common/lala/*').and_return(['d', 'e'])
    SdocAll::Paths.new(['*', '**']).add_tasks
  end

  describe "for hash config" do
    before do
      @root = mock(:root, :expand_path => mock(:root_exp, :exist? => true, :relative_path_from => "lala/root"))
      Pathname.should_receive(:new).with('/lalala/lala/root').and_return(@root)
      SdocAll::Paths.should_receive(:common_path).with([@root.expand_path]).and_return('/common')
    end

    it "should add task" do
      SdocAll::Base.should_receive(:add_task).with(:doc_path => "paths.lala.root", :src_path => @root.expand_path, :title => 'paths: lala/root')
      SdocAll::Paths.new({:root => '/lalala/lala/root'}).add_tasks
    end

    it "should add task with main" do
      SdocAll::Base.should_receive(:add_task).with(:doc_path => "paths.lala.root", :src_path => @root.expand_path, :main => 'special_readme', :title => 'paths: lala/root')
      SdocAll::Paths.new({:root => '/lalala/lala/root', :main => 'special_readme'}).add_tasks
    end

    it "should add task with with one include" do
      @file_list = mock(:file_list, :resolve => true)
      SdocAll::FileList.stub!(:new).and_return(@file_list)
      SdocAll::Base.should_receive(:chdir).with(@root.expand_path).and_yield
      @file_list.should_receive(:include).with('*.rb')
      @file_list.should_receive(:to_a).and_return(['a.rb', 'b.rb'])

      SdocAll::Base.should_receive(:add_task).with(:doc_path => "paths.lala.root", :src_path => @root.expand_path, :paths => ['a.rb', 'b.rb'], :title => 'paths: lala/root')
      SdocAll::Paths.new({:root => '/lalala/lala/root', :paths => '*.rb'}).add_tasks
    end

    it "should add task with with array of includes and excludes" do
      @file_list = mock(:file_list, :resolve => true)
      SdocAll::FileList.stub!(:new).and_return(@file_list)
      SdocAll::Base.should_receive(:chdir).with(@root.expand_path).and_yield
      @file_list.should_receive(:include).ordered.with('*.*')
      @file_list.should_receive(:exclude).ordered.with('*.cgi')
      @file_list.should_receive(:include).ordered.with('README')
      @file_list.should_receive(:include).ordered.with('README_*')
      @file_list.should_receive(:exclude).ordered.with('*.tmp')
      @file_list.should_receive(:to_a).and_return(['a.rb', 'b.rb', 'README', 'README_en'])

      SdocAll::Base.should_receive(:add_task).with(:doc_path => "paths.lala.root", :src_path => @root.expand_path, :paths => ['a.rb', 'b.rb', 'README', 'README_en'], :title => 'paths: lala/root')
      SdocAll::Paths.new({:root => '/lalala/lala/root', :paths => ['*.*', '-*.cgi', '+README', '+README_*', '-*.tmp']}).add_tasks
    end
  end

  describe "for array of hashes config" do
    it "should add task" do
      @root = mock(:root, :expand_path => mock(:root_exp, :exist? => true, :relative_path_from => "lala/root"))
      Pathname.should_receive(:new).with('/lalala/lala/root').and_return(@root)

      @other = mock(:other, :expand_path => mock(:other_exp, :exist? => true, :relative_path_from => "lolo/other"))
      Pathname.should_receive(:new).with('/lalala/lolo/other').and_return(@other)

      SdocAll::Paths.should_receive(:common_path).with([@root, @other].map(&:expand_path)).and_return('/common')

      SdocAll::Base.should_receive(:add_task).with(:doc_path => "paths.lala.root", :src_path => @root.expand_path, :title => 'paths: lala/root')
      SdocAll::Base.should_receive(:add_task).with(:doc_path => "paths.lolo.other", :src_path => @other.expand_path, :title => 'paths: lolo/other')

      SdocAll::Paths.new([{:root => '/lalala/lala/root'}, {:root => '/lalala/lolo/other'}]).add_tasks
    end
  end

  it "should add task for mixed config" do
    @roots = {}
    [:a, :b, :c, :d, :e, :f, :g].each do |sym|
      @roots[sym] = mock(sym, :expand_path => mock("#{sym}_exp".to_sym, :exist? => true, :relative_path_from => "lala/#{sym}_exp"))
      Pathname.should_receive(:new).with("#{sym}").and_return(@roots[sym])
      SdocAll::Base.should_receive(:add_task).with(:doc_path => "paths.lala.#{sym}_exp", :src_path => @roots[sym].expand_path, :title => "paths: lala/#{sym}_exp")
    end
    SdocAll::Paths.should_receive(:common_path).with(@roots.values_at(:a, :b, :c, :d, :e, :f, :g).map(&:expand_path)).and_return('/common')

    File.should_receive(:expand_path).with('*').and_return('/common/lala/*')
    Dir.should_receive(:[]).with('/common/lala/*').and_return(['b', 'c'])
    File.should_receive(:expand_path).with('**').and_return('/common/lala/**')
    Dir.should_receive(:[]).with('/common/lala/**').and_return(['e', 'f'])
    SdocAll::Paths.new([{:root => 'a'}, '*', {:root => 'd'}, '**', {:root => 'g'}]).add_tasks
  end
end
