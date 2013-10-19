describe "Application 'QuickHackerNews'" do
  before do
    @app = NSApplication.sharedApplication
  end

  it "has a status menu" do
    @app.delegate.status_menu.nil?.should == false
  end

  it "has three menu items" do
    @app.delegate.status_menu.itemArray.length.should == 3
  end
end
