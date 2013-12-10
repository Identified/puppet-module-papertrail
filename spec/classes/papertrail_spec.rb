require 'spec_helper'

describe 'papertrail', :type => :class do
  let(:title) { 'papertrail' }
  let(:facts) { { :operatingsystem => 'Debian', } }

  it do
    should contain_package('rsyslog', 'rsyslog-gnutls', 'wget').with({
      'ensure' => 'installed',
    })
  end

  it do
    should contain_file('/etc/rsyslog.d/papertrail.conf').with({
      'ensure'  => 'present',
      'owner'   => 'root',
      'group'   => 'root',
      'mode'    => '0640',
      'require' => '[Package[rsyslog]{:name=>"rsyslog"}, Package[rsyslog-gnutls]{:name=>"rsyslog-gnutls"}]',
      'notify'  => 'Service[rsyslog]',
    })
  end

  it do
    should contain_file('/etc/syslog.papertrail.crt').with({
      'ensure'  => 'present',
      'replace' => 'no',
      'owner'   => 'root',
      'group'   => 'root',
      'mode'    => '0660',
    })
  end

  it do
    should contain_exec('get_certificates').with({
      'path'    => '/bin/:/usr/bin/:/usr/local/bin/',
      'command' => 'wget https://papertrailapp.com/tools/syslog.papertrail.crt -O /etc/syslog.papertrail.crt',
      'creates' => '/etc/syslog.papertrail.crt',
    })
  end

  it do
    should contain_service('rsyslog').with({
      'ensure' => 'running',
    })
  end

  describe 'template' do
    let(:params) do {
        :host                             => 'logs.papertrailapp.com',
        :port                             => '12839',
        :action_resume_interval           => 10,
        :action_queue_size                => 100000,
        :action_discard_mark              => 97500,
        :action_queue_high_watermark      => 80000,
        :action_queue_type                => 'LinkedList',
        :action_queue_filename            => 'papertrailqueue',
        :action_queue_checkpoint_interval => 100,
        :action_queue_max_disk_space      => '1G',
        :action_resume_retry_count        => '-1',
        :action_queue_save_on_shutdown    => 'on',
        :action_queue_timeout_enqueue     => 10,
        :action_queue_discard_severity    => 0,
        :cert_url                         => 'https://papertrailapp.com/tools/syslog.papertrail.crt',
        :cert                             => '/etc/syslog.papertrail.crt',
        :optional_files                   => [],
        :logger_priority_facility         => 'user',
        :logger_priority_level            => 'notice'
    }
    end

    it 'should generate valid content for papertrail.conf' do

      content = catalogue(:class).resource('file', '/etc/rsyslog.d/papertrail.conf').send(:parameters)[:content]

      content.should match(/^\$DefaultNetstreamDriverCAFile \/etc\/syslog.papertrail.crt    # trust these CAs$/)
      content.should match(/^\$DefaultNetstreamDriver gtls                                # use gtls netstream driver$/)
      content.should match(/^\$ActionSendStreamDriverMode 1                               # require TLS$/)
      content.should match(/^\$ActionSendStreamDriverAuthMode x509\/name                   # authenticate by hostname$/)
      content.should match(/^\$ActionResumeInterval 10$/)
      content.should match(/^\$ActionQueueSize 100000$/)
      content.should match(/^\$ActionQueueDiscardMark 97500$/)
      content.should match(/^\$ActionQueueHighWaterMark 80000$/)
      content.should match(/^\$ActionQueueType LinkedList$/)
      content.should match(/^\$ActionQueueFileName papertrailqueue$/)
      content.should match(/^\$ActionQueueCheckpointInterval 100$/)
      content.should match(/^\$ActionQueueMaxDiskSpace 1G$/)
      content.should match(/^\$ActionResumeRetryCount -1$/)
      content.should match(/^\$ActionQueueSaveOnShutdown on$/)
      content.should match(/^\$ActionQueueTimeoutEnqueue 10$/)
      content.should match(/^\$ActionQueueDiscardSeverity 0$/)

      content.should match(/^user\.notice @@logs\.papertrailapp\.com:12839$/)


    end
  end

end
