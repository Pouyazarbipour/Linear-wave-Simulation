%% POUYA ZARBIPOUR LAKPOSHTEH EMAIL: pouyazarbipour@gmail.com
classdef LWaveSimulation < handle
    properties
        fig % Main GUI figure
        plotPanel % Axes for plotting
        inputPanel % Panel for input controls

        H % Wave height
        T % Wave period
        d % Local depth
        L % Wavelength

        stopFlag = false; % Stop flag for the wave simulation
        timerObj % Timer for updating the wave simulation
    end

    methods
        %% Constructor
        function obj = LWaveSimulation()
            obj.initGUI();
        end

        %% GUI Initialization
        function initGUI(obj)
            % Create main figure
            obj.fig = uifigure('Name', 'Linear Plot', 'Position', [100, 100, 800, 400]);

            % Create input panel
            obj.inputPanel = uipanel(obj.fig, 'Title', 'Input Wave Data', ...
                'Position', [10, 50, 200, 300]);

            % Wave Height input
            uilabel(obj.inputPanel, 'Text', 'Wave Height (m):', 'Position', [10, 240, 150, 22]);
            heightInput = uieditfield(obj.inputPanel, 'numeric', 'Position', [10, 220, 180, 22]);
            heightInput.Value = 2; % Default value

            % Wave Period input
            uilabel(obj.inputPanel, 'Text', 'Wave Period (s):', 'Position', [10, 180, 150, 22]);
            periodInput = uieditfield(obj.inputPanel, 'numeric', 'Position', [10, 160, 180, 22]);
            periodInput.Value = 6; % Default value

            % Local Depth input
            uilabel(obj.inputPanel, 'Text', 'Local Depth (m):', 'Position', [10, 120, 150, 22]);
            depthInput = uieditfield(obj.inputPanel, 'numeric', 'Position', [10, 100, 180, 22]);
            depthInput.Value = 10; % Default value

            % Buttons
            calculateBtn = uibutton(obj.inputPanel, 'Text', 'Calculate', ...
                'Position', [10, 50, 80, 30], 'ButtonPushedFcn', @(~,~) obj.handleCalculate(heightInput, periodInput, depthInput));
            stopBtn = uibutton(obj.inputPanel, 'Text', 'Stop', ...
                'Position', [110, 50, 80, 30], 'ButtonPushedFcn', @(~,~) obj.handleStop());

            % Create plot panel
            obj.plotPanel = uiaxes(obj.fig, 'Position', [250, 50, 500, 300]);
            title(obj.plotPanel, 'Wave Simulation');
            xlabel(obj.plotPanel, 'Distance (m)');
            ylabel(obj.plotPanel, 'Height (m)');
        end

        %% Handle Calculate Button
        function handleCalculate(obj, heightInput, periodInput, depthInput)
            obj.H = heightInput.Value;
            obj.T = periodInput.Value;
            obj.d = depthInput.Value;

            % Validate inputs
            if isempty(obj.H) || isempty(obj.T) || isempty(obj.d) || ...
                    obj.H <= 0 || obj.T <= 0 || obj.d <= 0
                uialert(obj.fig, 'Please enter valid positive numbers for all inputs.', 'Invalid Input');
                return;
            end

            % Adjust wave height if it exceeds 0.8 * depth
            if obj.H > 0.8 * obj.d
                obj.H = 0.8 * obj.d;
                heightInput.Value = obj.H; % Update value in UI
                uialert(obj.fig, 'Wave height adjusted due to breaking limit.', 'Wave Breaking');
            end

            % Calculate wave properties
            obj.L = obj.calculateWavelength(obj.d, obj.T);

            % Start the wave simulation
            obj.stopFlag = false;
            if ~isempty(obj.timerObj)
                stop(obj.timerObj);
                delete(obj.timerObj);
            end

            % Create and start the timer for wave simulation
            obj.timerObj = timer('ExecutionMode', 'fixedRate', ...
                'Period', 0.1, ...
                'TimerFcn', @(~,~) obj.updateWave());
            start(obj.timerObj);
        end

        %% Handle Stop Button
        function handleStop(obj)
            obj.stopFlag = true;
            if ~isempty(obj.timerObj)
                stop(obj.timerObj);
                delete(obj.timerObj);
            end
        end

        %% Update Wave Simulation
        function updateWave(obj)
            if obj.stopFlag
                return;
            end

            % Calculate wave points
            x = linspace(0, 10 * obj.L, 500); % Distance
            omega = 2 * pi / obj.T; % Angular frequency
            k = 2 * pi / obj.L; % Wave number
            t = now * 24 * 3600; % Time in seconds
            y = obj.H / 2 * cos(k * x - omega * t); % Wave height

            % Plot wave
            plot(obj.plotPanel, x, y, 'b');
            ylim(obj.plotPanel, [-obj.H, obj.H]);
            drawnow;
        end

        %% Calculate Wavelength
        function L = calculateWavelength(~, d, T)
            g = 9.81; % Gravity
            omega = 2 * pi / T; % Angular frequency

            % Use iterative method to solve for wavelength
            L = T * sqrt(g * d); % Initial guess
            for i = 1:10
                L = g * T^2 / (2 * pi) * tanh(2 * pi * d / L);
            end
        end
    end
end
