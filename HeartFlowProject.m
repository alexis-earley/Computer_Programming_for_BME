% Alexis Earley
% BME 5937
% Final Project

% Citation: function outlines were taken from the BME 5913 "Final Project 
% Algorithm and Function Descriptions" slides

clear;
clc;

% Import flow.csv file
flowData = load('flow.csv');

% Smooth the data
smoothedFlowData = [flowData(:,1), smooth(flowData(:,2))];

% Use the processFlow function to divide up the data into cycles based on
% troughs
[troughs, cycle_times, cycle_flows, areas] = processFlow(smoothedFlowData);

% Show the results using the displayResults function
displayResults(flowData, smoothedFlowData, troughs, cycle_times, cycle_flows, areas);

function [troughs, cycle_times, cycle_flows, areas] = processFlow(flowData)
% Processes the smoothed flow data
%
% Usage:
% [troughs, times, cycles, areas] = processFlow(flowData)
%
% Input:
% flowData : Array of time and flow data values.
% Output:
% troughs : Array of indices and times of troughs
% cycle_times : Cell array of measurement times per cycle
% cycle_flows : Cell array of flow measurements per cycle
% areas : Array of areas under flow curves

% Search for troughs before high peaks
[troughs] = findTroughs(flowData);

% Split up into cycles based on trough positions & compute areas
[cycle_times, cycle_flows, areas] = findCycles(flowData, troughs);

end


function [troughs] = findTroughs(flowData)
% Find troughs in the smoothed flow data
%
% Usage:
%
% [troughs] = findTroughs(flowData)
%
% Input
% flowData : Array of time and flow data values.
% Output
% troughs : Array of indices of troughs, each index corresponds to a row
% in the flow data array

% Initialize list of peak and trough indices
troughs = [];

% Import second column of the flowData matrix (contains flow values)
flowVals = flowData(:,2);

% Iterate through possible peaks (all but first and last two points)
for i = 3:(length(flowVals) - 2)

    % Find the flow at that index
    currVal = flowVals(i);

    % Look to see if the flow meets the requirements for being a peak
    meetsThreshold = (currVal > 300); % It is larger than 300
    moreThanNearPts = (currVal > flowVals(i - 1)) && (currVal > flowVals(i + 1)); % It is greater than the predeccessor 
    % and the successor
    highPredecessor = (flowVals(i - 1) > flowVals(i - 2)); % The predeccessor is greater than the one two before it
    highSuccessor = (flowVals(i + 1) > flowVals(i + 2)); % The successor is greater than the one two after it

    if (meetsThreshold && moreThanNearPts && highPredecessor && highSuccessor) %% If the value is a peak

        for j = (i-1):-1:(i-10) % Examine the 10 prior points to see if any are a trough
            if (flowVals(j) < flowVals(j - 1)) % If that flow value is less or equal to the one before
                troughs(end + 1) = j; % Add the flow values' index to the list of troughs
                break; % Stop looking for a trough
            end
        end
    end
end

end



function [cycle_times, cycle_flows, areas] = findCycles(flowData, troughs)
% Get cycles, times and areas for the smoothed flow data
%
% Usage:
% [cycle_times, cycle_flows, areas] = findCycles(flowData, troughs)
%
% Input
% flowData : Array of flow and time data values.
% troughs : Array of indices troughs
% Output
% cycle_times : Cell array of measurement times per cycle
% cycle_flows : Cell array of flow measurements per cycle
% areas : Array of areas under flow curves
% Split up into cycles based on trough positions & compute areas

% Get first and second columns (time and flow values, respectively) from 
% the flowData matrix
timeVals = flowData(:,1);
flowVals = flowData(:,2);

% Intialize variables
cycle_times = {};
cycle_flows = {};
areas = [];

% Iterate through all but the last trough
% That trough is excluded because it will lead to an incomplete cycle
for i = 1:(length(troughs) - 1)

    % Create arrays out of all time and flow values in each cycle
    % (A cycle goes from one trough to the next)

    timeArray = timeVals(troughs(i):(troughs(i+1)- 1));
    cycleArray = flowVals(troughs(i):(troughs(i+1) - 1));

    % Add all times and flows to ongoing cell arrays
    cycle_times{end+1} = timeArray;
    cycle_flows{end+1} = cycleArray;

    % Add the area under each cycle to the array of areas
    % By using trapezoidal rule, we can find the area accurately
    areas(end+1) = trapz(timeArray,cycleArray); 
    % THIS IS WHERE THE TRAPEZOIDAL RULE FUNCTION WAS USED

end

end



function displayResults(flowData, smoothedFlowData, troughs, cycle_times, cycle_flows, areas)
% Processes the smoothed flow data
%
% Usage:
%
% displayResults(flow, smoothedFlow, troughs, cycle_times, cycle_flows, areas);
%
% Input
% flowData : Array of original time and flow data values.
% smoothFlowData : Array of time and smoothed flow data values.
% troughs : Array of indices for the troughs.
% cycle_times : Cell array of measurement times per cycle.
% cycle_flows : Cell array of flow measurements per cycle.
% areas : Array of areas under flow curves for each cycle.

% Display mean and standard deviation of areas
fprintf('Mean/std dev of areas under curves = %0.2f +/- %0.2f \n', mean(areas), std(areas));

% Plot the original time vs. flow data
subplot(2,2,1);
plot(flowData(:,1), flowData(:,2), 'b');

% Label plot
title('Original flow');
xlabel('Time (ms)');
ylabel('Flow');


% Plot the smoothed time vs. flow data, along with the troughs
subplot(2,2,2);
plot(smoothedFlowData(:,1), smoothedFlowData(:,2), 'b')
hold on

% Use trough indices to find each's corresponding time and flow values
for i = 1:(length(troughs))
    troughIdx = troughs(i);
    xVal = smoothedFlowData(troughIdx, 1);
    yVal = smoothedFlowData(troughIdx, 2);

    % Use these x- and y-values to graph each trough
    plot(xVal,yVal,'rx');
end

% Label plot
title('Smoothed flow');
xlabel('Time (ms)');
ylabel('Flow');
legend('Data', 'Cycle starting points')

% Plot each cycle
subplot(2,2,3);

% Iterate through the cell arrays with the times and flows in each cycle
for i = 1:length(cycle_times)
    % For each cycle, plot all of the times and flows
    % Note that times should be adjusted so the first time is always 0
    plot((cycle_times{i} - cycle_times{i}(1)),cycle_flows{i},'b')
    hold on
end

% Label plot
title('Flow cycles');
xlabel('Time (ms)');
ylabel('Flow');

% Plot a histogram of all of the area values, dividing into 9 categories
subplot(2,2,4);

hist(areas, 9)

% Label plot
title('Histogram of area values');
xlabel('Area under curves');
ylabel('Count');

end