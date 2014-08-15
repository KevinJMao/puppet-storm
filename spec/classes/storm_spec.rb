require 'spec_helper'

describe 'storm' do
  context 'supported operating systems' do
    ['RedHat'].each do |osfamily|
      ['RedHat', 'CentOS', 'Amazon', 'Fedora'].each do |operatingsystem|
        let(:facts) {{
          :osfamily        => osfamily,
          :operatingsystem => operatingsystem,
        }}

        default_configuration_file  = '/opt/storm/conf/storm.yaml'

        context "with explicit data (no Hiera)" do

          describe "storm class with default settings on #{osfamily}" do
            let(:params) {{ }}
            # We must mock $::operatingsystem because otherwise this test will
            # fail when you run the tests on e.g. Mac OS X.
            it { should compile.with_all_deps }

            it { should contain_class('storm::params') }
            it { should contain_class('storm::users').that_comes_before('storm::install') }
            it { should contain_class('storm::install').that_comes_before('storm::config') }
            it { should contain_class('storm::config') }

            it { should contain_package('storm').with_ensure('present') }

            it { should contain_group('storm').with({
              'ensure'     => 'present',
              'gid'        => 53001,
            })}

            it { should contain_user('storm').with({
              'ensure'     => 'present',
              'home'       => '/home/storm',
              'shell'      => '/bin/bash',
              'uid'        => 53001,
              'comment'    => 'Storm system account',
              'gid'        => 'storm',
              'managehome' => true,
            })}

            it { should contain_file('/app/storm').with({
              'ensure'       => 'directory',
              'owner'        => 'storm',
              'group'        => 'storm',
              'mode'         => '0750',
              'recurse'      => true,
              'recurselimit' => 0,
            })}

            it { should contain_file('/var/log/storm').with({
              'ensure' => 'directory',
              'owner'  => 'storm',
              'group'  => 'storm',
              'mode'   => '0755',
            })}

            it { should contain_file('/opt/storm/logs').with({
              'ensure' => 'link',
              'target' => '/var/log/storm',
            })}

            it { should contain_file(default_configuration_file).
              with({
                'ensure' => 'file',
                'owner'  => 'root',
                'group'  => 'root',
                'mode'   => '0644',
              }).
              with_content(/^storm\.zookeeper\.servers:\n  - zookeeper1\n$/).
              with_content(/^nimbus\.host: "nimbus1"$/).
              with_content(/^storm\.local\.dir: "\/app\/storm"$/).
              with_content(/^logviewer\.childopts: "-Xmx128m -Djava\.net\.preferIPv4Stack=true"$/).
              with_content(/^nimbus\.childopts: "-Xmx256m -Djava\.net\.preferIPv4Stack=true"$/).
              with_content(/^ui\.childopts: "-Xmx256m -Djava\.net\.preferIPv4Stack=true"$/).
              with_content(/^supervisor\.childopts: "-Xmx256m -Djava\.net\.preferIPv4Stack=true"$/).
              with_content(/^worker\.childopts: "-Xmx256m -Djava\.net\.preferIPv4Stack=true"$/).
              with_content(/^supervisor\.slots\.ports:\n  - 6700\n  - 6701\n$/).
              with_content(/^storm\.messaging\.transport: "backtype\.storm\.messaging\.netty\.Context"$/).
              without_content(/^drpc.servers:\n$/)
            }

            it { should contain_file('/opt/storm/logback/cluster.xml').
              with({
                'ensure' => 'file',
                'owner'  => 'root',
                'group'  => 'root',
                'mode'   => '0644',
              }).
              with_content(/^### This file is managed by Puppet\.$/).
              with_content(Regexp.new(Regexp.quote('<file>/var/log/storm/${logfile.name}</file>'))).
              with_content(
                Regexp.new(Regexp.quote('<fileNamePattern>/var/log/storm/${logfile.name}.%i</fileNamePattern>')
              )).
              with_content(/<file>\/var\/log\/storm\/access\.log<\/file>$/).
              with_content(/<fileNamePattern>\/var\/log\/storm\/access\.log\.%i<\/fileNamePattern>$/).
              with_content(/<file>\/var\/log\/storm\/metrics\.log<\/file>$/).
              with_content(/<fileNamePattern>\/var\/log\/storm\/metrics\.log\.%i<\/fileNamePattern>$/)
            }

          end

          describe "storm class with three DRPC servers on #{osfamily}" do
            let(:params) {{
              :drpc_servers => ['drpc1', 'drpc2', 'drpc3'],
            }}
            it { should contain_file(default_configuration_file).
              with_content(/^drpc\.servers:\n  - drpc1\n  - drpc2\n  - drpc3\n$/)
            }
          end

          describe "storm class with drpc servers set to a string instead of an array on #{osfamily}" do
            let(:params) {{
              :drpc_servers => 'drpc1',
            }}
            it { expect { should contain_class('storm') }.
              to raise_error(Puppet::Error, /"drpc1" is not an Array.  It looks to be a String/) }
          end

          describe "storm class with three ZooKeeper servers on #{osfamily}" do
            let(:params) {{
              :zookeeper_servers => ['zookeeper1', 'zkserver2', 'zkserver3'],
            }}
            it { should contain_file(default_configuration_file).
              with_content(/^storm\.zookeeper\.servers:\n  - zookeeper1\n  - zkserver2\n  - zkserver3\n$/)
            }
          end

          describe "storm class with Graphite enabled" do 
            let(:params) {{ 
              :graphite_enable          => true, 
              :graphite_consumer        => 'backtype.storm.metric.GraphiteMetricsConsumer',
              :graphite_hostname        => 'cde-graphite.cde.vrsn.com', 
              :graphite_package_ensure  => 'present', 
              :graphite_package_name    => 'storm-graphite', 
              :graphite_port            => '2003', 
              :graphite_prefix          => 'storm' 
            }} 

            it { should contain_package('storm-graphite').with_ensure('present')} 
            it { should contain_file(default_configuration_file).
                    with_content(/^topology\.metrics\.consumer\.register:\n  - class: "backtype\.storm\.metric\.GraphiteMetricsConsumer"$/).
               with_content(/^metrics\.graphite\.host: "cde-graphite\.cde\.vrsn\.com"$/). 
            with_content(/^metrics\.graphite\.port: "2003"$/). 
            with_content(/^metrics\.graphite\.prefix: "storm"$/) 
            }
          end

          describe "storm class with zookeeper servers set to a string instead of an array on #{osfamily}" do
            let(:params) {{
              :zookeeper_servers => 'zookeeper1',
            }}
            it { expect { should contain_class('storm') }.
              to raise_error(Puppet::Error, /"zookeeper1" is not an Array.  It looks to be a String/) }
          end

          describe "storm class with messaging backend set to ZeroMQ on #{osfamily}" do
            let(:params) {{
              :storm_messaging_transport => 'backtype.storm.messaging.zmq',
            }}
            it { should contain_file(default_configuration_file).
              with_content(/^storm\.messaging\.transport: "backtype\.storm\.messaging\.zmq"$/)
            }
          end

          describe "storm class with custom drpc childopts on #{osfamily}" do
            let(:params) {{
              :drpc_childopts => '-Xmx512m -Xms512m',
            }}
            it { should contain_file(default_configuration_file).
              with_content(/^drpc\.childopts: "-Xmx512m -Xms512m"$/).
              with_content(/^logviewer\.childopts: "-Xmx128m -Djava\.net\.preferIPv4Stack=true"$/).
              with_content(/^nimbus\.childopts: "-Xmx256m -Djava\.net\.preferIPv4Stack=true"$/).
              with_content(/^ui\.childopts: "-Xmx256m -Djava\.net\.preferIPv4Stack=true"$/).
              with_content(/^supervisor\.childopts: "-Xmx256m -Djava\.net\.preferIPv4Stack=true"$/).
              with_content(/^worker\.childopts: "-Xmx256m -Djava\.net\.preferIPv4Stack=true"$/)
            }
          end

          describe "storm class with custom logviewer childopts on #{osfamily}" do
            let(:params) {{
              :logviewer_childopts => '-Xmx512m -Xms512m',
            }}
            it { should contain_file(default_configuration_file).
              with_content(/^drpc\.childopts: "-Xmx256m -Djava\.net\.preferIPv4Stack=true"$/).
              with_content(/^logviewer\.childopts: "-Xmx512m -Xms512m"$/).
              with_content(/^nimbus\.childopts: "-Xmx256m -Djava\.net\.preferIPv4Stack=true"$/).
              with_content(/^ui\.childopts: "-Xmx256m -Djava\.net\.preferIPv4Stack=true"$/).
              with_content(/^supervisor\.childopts: "-Xmx256m -Djava\.net\.preferIPv4Stack=true"$/).
              with_content(/^worker\.childopts: "-Xmx256m -Djava\.net\.preferIPv4Stack=true"$/)
            }
          end

          describe "storm class with custom nimbus childopts on #{osfamily}" do
            let(:params) {{
              :nimbus_childopts => '-Xmx1024m -Xms512m',
            }}
            it { should contain_file(default_configuration_file).
              with_content(/^drpc\.childopts: "-Xmx256m -Djava\.net\.preferIPv4Stack=true"$/).
              with_content(/^logviewer\.childopts: "-Xmx128m -Djava\.net\.preferIPv4Stack=true"$/).
              with_content(/^nimbus\.childopts: "-Xmx1024m -Xms512m"$/).
              with_content(/^ui\.childopts: "-Xmx256m -Djava\.net\.preferIPv4Stack=true"$/).
              with_content(/^supervisor\.childopts: "-Xmx256m -Djava\.net\.preferIPv4Stack=true"$/).
              with_content(/^worker\.childopts: "-Xmx256m -Djava\.net\.preferIPv4Stack=true"$/)
            }
          end

          describe "storm class with custom supervisor childopts on #{osfamily}" do
            let(:params) {{
              :supervisor_childopts => '-Xmx1024m -Xms512m',
            }}
            it { should contain_file(default_configuration_file).
              with_content(/^drpc\.childopts: "-Xmx256m -Djava\.net\.preferIPv4Stack=true"$/).
              with_content(/^logviewer\.childopts: "-Xmx128m -Djava\.net\.preferIPv4Stack=true"$/).
              with_content(/^nimbus\.childopts: "-Xmx256m -Djava\.net\.preferIPv4Stack=true"$/).
              with_content(/^ui\.childopts: "-Xmx256m -Djava\.net\.preferIPv4Stack=true"$/).
              with_content(/^supervisor\.childopts: "-Xmx1024m -Xms512m"$/).
              with_content(/^worker\.childopts: "-Xmx256m -Djava\.net\.preferIPv4Stack=true"$/)
            }
          end

          describe "storm class with custom ui childopts on #{osfamily}" do
            let(:params) {{
              :ui_childopts => '-Xmx1024m -Xms512m',
            }}
            it { should contain_file(default_configuration_file).
              with_content(/^drpc\.childopts: "-Xmx256m -Djava\.net\.preferIPv4Stack=true"$/).
              with_content(/^logviewer\.childopts: "-Xmx128m -Djava\.net\.preferIPv4Stack=true"$/).
              with_content(/^nimbus\.childopts: "-Xmx256m -Djava\.net\.preferIPv4Stack=true"$/).
              with_content(/^ui\.childopts: "-Xmx1024m -Xms512m"$/).
              with_content(/^supervisor\.childopts: "-Xmx256m -Djava\.net\.preferIPv4Stack=true"$/).
              with_content(/^worker\.childopts: "-Xmx256m -Djava\.net\.preferIPv4Stack=true"$/)
            }
          end

          describe "storm class with custom worker childopts on #{osfamily}" do
            let(:params) {{
              :worker_childopts => '-Xmx1024m -Xms512m',
            }}
            it { should contain_file(default_configuration_file).
              with_content(/^drpc\.childopts: "-Xmx256m -Djava\.net\.preferIPv4Stack=true"$/).
              with_content(/^logviewer\.childopts: "-Xmx128m -Djava\.net\.preferIPv4Stack=true"$/).
              with_content(/^nimbus\.childopts: "-Xmx256m -Djava\.net\.preferIPv4Stack=true"$/).
              with_content(/^ui\.childopts: "-Xmx256m -Djava\.net\.preferIPv4Stack=true"$/).
              with_content(/^supervisor\.childopts: "-Xmx256m -Djava\.net\.preferIPv4Stack=true"$/).
              with_content(/^worker\.childopts: "-Xmx1024m -Xms512m"$/)
            }
          end

          describe "storm class with custom nimbus host on #{osfamily}" do
            let(:params) {{
              :nimbus_host => 'master23',
            }}
            it { should contain_file(default_configuration_file).
              with_content(/^nimbus\.host: "master23"$/)
            }
          end

          describe "storm class with custom supervisor slots ports on #{osfamily}" do
            let(:params) {{
              :supervisor_slots_ports => [1000, 2000, 3000, 4000],
            }}
            it { should contain_file(default_configuration_file).
              with_content(/^supervisor\.slots\.ports:\n  - 1000\n  - 2000\n  - 3000\n  - 4000\n$/)
            }
          end

          describe "storm class with supervisor slots ports set to a number instead of an array on #{osfamily}" do
            let(:params) {{
              :supervisor_slots_ports => 6700,
            }}
            it { expect { should contain_class('storm') }.
              to raise_error(Puppet::Error, /"6700" is not an Array.  It looks to be a String/) }
          end

          describe "storm class with disabled user management on #{osfamily}" do
            let(:params) {{
              :user_manage  => false,
            }}
            it { should_not contain_group('storm') }
            it { should_not contain_user('storm') }
          end

          describe "storm class with custom user and group on #{osfamily}" do
            let(:params) {{
              :user_manage      => true,
              :gid              => 456,
              :group            => 'stormgroup',
              :uid              => 123,
              :user             => 'stormuser',
              :user_description => 'Apache Storm user',
              :user_home        => '/home/stormuser',
            }}

            it { should_not contain_group('storm') }
            it { should_not contain_user('storm') }

            it { should contain_user('stormuser').with({
              'ensure'     => 'present',
              'home'       => '/home/stormuser',
              'shell'      => '/bin/bash',
              'uid'        => 123,
              'comment'    => 'Apache Storm user',
              'gid'        => 'stormgroup',
              'managehome' => true,
            })}

            it { should contain_group('stormgroup').with({
              'ensure'     => 'present',
              'gid'        => 456,
            })}
          end

          describe "storm class with custom local directory on #{osfamily}" do
            let(:params) {{
              :local_dir => '/var/lib/storm',
            }}

            it { should contain_file('/var/lib/storm').with({
              'ensure'       => 'directory',
              'owner'        => 'storm',
              'group'        => 'storm',
              'mode'         => '0750',
              'recurse'      => true,
              'recurselimit' => 0,
            })}
            it { should_not contain_file('/app/storm') }

            it { should contain_file(default_configuration_file).
              with_content(/^storm\.local\.dir: "\/var\/lib\/storm"$/)
            }
          end

          describe "storm class with custom local hostname on #{osfamily}" do
            let(:params) {{
              :local_hostname  => 'foohost',
            }}
            it { should contain_file(default_configuration_file).with_content(/^storm\.local\.hostname: "foohost"$/) }
          end

          describe "storm class with custom config map on #{osfamily}" do
            let(:params) {{
              :config_map => {
                'nimbus.cleanup.inbox.freq.secs' => 666,
                'nimbus.monitor.freq.secs' => 22,
                'topology.kryo.register' => [
                  'org.mycompany.MyType',
                  { 'org.mycompany.MyType2' => 'org.mycompany.MyType2Serializer' },
                ],
              },
            }}
            it { should contain_file(default_configuration_file).
              with_content(/^nimbus\.cleanup\.inbox\.freq\.secs: "666"$/).
              with_content(/^nimbus\.monitor\.freq\.secs: "22"$/).
              with_content(/^topology.kryo.register:\n  - org.mycompany.MyType\n  - org.mycompany.MyType2: org.mycompany.MyType2Serializer$/).
              without_content(/^---/)
            }
          end

        end

        context "with Hiera data" do

          describe "storm class with custom config map on #{osfamily}" do
            let(:hiera_config) { Hiera_yaml }
            hiera = Hiera.new(:config => Hiera_yaml)
            config_map = hiera.lookup('storm::config_map', nil, nil)
            let(:params) {{
              :config_map => config_map
            }}

            it { should contain_file(default_configuration_file).
              with_content(/^nimbus\.cleanup\.inbox\.freq\.secs: "777"$/).
              with_content(/^nimbus\.monitor\.freq\.secs: "33"$/).
              with_content(/^topology.kryo.register:\n  - org.mycompany.MyFirstType\n  - org.mycompany.MySecondType: org.mycompany.MySecondTypeSerializer$/).
              without_content(/^---/)
            }
          end

        end

      end
    end
  end

  context 'unsupported operating system' do
    describe 'storm class without any parameters on Debian' do
      let(:facts) {{
        :osfamily => 'Debian',
      }}

      it { expect { should contain_package('storm') }.to raise_error(Puppet::Error,
        /The storm module is not supported on a Debian based system./) }
    end
  end
end
