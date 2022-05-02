require "spec_helper"
require "serverspec"

package = "fab_manager"
service = "fab_manager"
config  = "/etc/fab_manager/fab_manager.conf"
user    = "fab_manager"
group   = "fab_manager"
ports   = [PORTS]
log_dir = "/var/log/fab_manager"
db_dir  = "/var/lib/fab_manager"

case os[:family]
when "freebsd"
  config = "/usr/local/etc/fab_manager.conf"
  db_dir = "/var/db/fab_manager"
end

describe package(package) do
  it { should be_installed }
end

describe file(config) do
  it { should be_file }
  its(:content) { should match Regexp.escape("fab_manager") }
end

describe file(log_dir) do
  it { should exist }
  it { should be_mode 755 }
  it { should be_owned_by user }
  it { should be_grouped_into group }
end

describe file(db_dir) do
  it { should exist }
  it { should be_mode 755 }
  it { should be_owned_by user }
  it { should be_grouped_into group }
end

case os[:family]
when "freebsd"
  describe file("/etc/rc.conf.d/fab_manager") do
    it { should be_file }
  end
end

describe service(service) do
  it { should be_running }
  it { should be_enabled }
end

ports.each do |p|
  describe port(p) do
    it { should be_listening }
  end
end
