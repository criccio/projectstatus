Projectstatus::Application.configure do

  config.update_interval = 20.minutes

  config.build_window = 7.days

  # map of auth tokens for various jenkins servers
  # hash key will be used in a regex of the jenkins url to determine if it should be used
  # keep this map empty if anonymous users can access the job page
  config.jenkins_auth_map = {}
  config.jenkins_auth_map['node name'] = { user: 'user', pw: 'password'}

  #user names if you want to filter to only your team members
  config.jenkins_participant_map = {}
  config.jenkins_participant_map['node name'] = { users: %w(criccio)}

end


