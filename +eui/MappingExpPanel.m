classdef MappingExpPanel < eui.ExpPanel
  %EUI.MAPPINGEXPPANEL Preliminary UI for monitoring a mapping experiment
  %   TODO
  %
  % Part of Rigbox

  % 2013-07 CB created
  
  properties
  end
  
  properties (Access = protected)
    StimAxes
  end
  
  methods
    function obj = MappingExpPanel(parent, ref, logEntry, params)
      obj = obj@eui.ExpPanel(parent, ref, logEntry, params);
    end
  end
  
  methods (Access = protected)
    function event(obj, name, t)
      event@eui.ExpPanel(obj, name, t); %call superclass method
      switch name
        case 'stimulusStarted'
          %plot a disc centred at the stimulus location
          conds = [obj.Block.trial.condition];
%           colour = conds(end).colour;
          pos = [conds.position];
%           if isfield(conds, 'size')
%             sz = conds(end).size;
%           else
%             sz = obj.Block.parameters.size;
%           end
          x = pos(end);
          
%           fprintf('(%.2g, %.2g)\n', x(1), y(1));
%           colours = [leftColour; rightColour];
          obj.StimAxes.XLim = [min(pos) max(pos)] + [-10 10];% + [-sz sz];
          obj.StimAxes.plot([x x], [-10 50], 'k', 'LineWidth', 5);
%           obj.StimAxes.XLim = 1.1*[-max(azis) max(azis)];
%           obj.StimAxes.scatter(x, y, 500, colours, 'filled');
        case 'stimulusEnded'
          %clear the plot
          obj.StimAxes.clear();
      end
    end
    
    function build(obj, parent)
      build@eui.ExpPanel(obj, parent); %call superclass method
      
      obj.StimAxes = bui.Axes(obj.CustomPanel);
      obj.StimAxes.XLim = [-70 70];
      obj.StimAxes.YLim = [-10 50];
      obj.StimAxes.yLabel('Elevation (deg)');
      obj.StimAxes.xLabel('Azimiuth (deg)');
      obj.StimAxes.NextPlot = 'replacechildren';
      
    end
  end
    
end

