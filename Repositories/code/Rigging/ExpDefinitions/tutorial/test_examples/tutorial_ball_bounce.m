function tutorial_ball_bounce(t, events, pars, visStim, inputs, outputs, audio)
% Testing visual stimuli in signals

%% Visual stim

initial_position = rand(1,2).*[180,90];
initial_velocity = rand(1,2).*3;
update_t = 0.01; % how often to update the position

initial_ball_properties.position = initial_position;
initial_ball_properties.velocity = initial_velocity;

initial_ball_properties = events.expStart.map(@(x) initial_ball_properties);

t_ball = skipRepeats(t - mod(t,update_t));
ball_properties = t_ball.scan(@update_ball,initial_ball_properties).subscriptable;

ball = vis.patch(t,'rectangle');
ball.azimuth = ball_properties.position(1);
ball.altitude = ball_properties.position(2);
ball.dims = [10,10];
ball.show = true;

visStim.target = ball;

%% Define events to save

events.t_ball = t_ball;
events.endTrial = events.newTrial.delay(5);

end


function ball_position = update_ball(ball_position,t_ball)

if abs(ball_position.position(1)) > 180
    ball_position.velocity(1) = -ball_position.velocity(1);
end

if abs(ball_position.position(2)) > 90
    ball_position.velocity(2) = -ball_position.velocity(2);
end

ball_position.position = ball_position.position + ball_position.velocity;


end











