function [f,g] = MLPSoftmaxLossWithDropout(w,X,y,nHidden,nLabels,pDropout)
Softmax = @(y) exp(y) ./ sum(exp(y));
assert(length(pDropout) == length(nHidden) + 1);
[nInstances,nVars] = size(X);
% Form Weights
inputWeights = reshape(w(1:nVars*nHidden(1)),nVars,nHidden(1));
offset = nVars*nHidden(1);
for h = 2:length(nHidden)
  hiddenWeights{h-1} = reshape(w(offset+1:offset+nHidden(h-1)*nHidden(h)),nHidden(h-1),nHidden(h));
  offset = offset+nHidden(h-1)*nHidden(h);
end
% there is no need to distinguish output and hidden
hiddenWeights{length(nHidden)} = w(offset+1:offset+nHidden(end)*nLabels);
hiddenWeights{length(nHidden)} = reshape(hiddenWeights{end},nHidden(end),nLabels);

f = 0;
if nargout > 1
    gInput = zeros(size(inputWeights));
    for h = 1:length(nHidden)
       gHidden{h} = zeros(size(hiddenWeights{h})); 
    end
end

% dropout mask, with propability 1-p to be 1
dropoutInput = rand(1, nVars) < (1 - pDropout(1));
for h = 1:length(nHidden)
    dropoutMask{h} = rand(1, nHidden) < (1 - pDropout(h));
end

% Compute Output
for i = 1:nInstances
    ip{1} = (X(i,:) .* dropoutInput) * inputWeights;
    fp{1} = dropoutMask{1} .* tanh(ip{1});
    for h = 2:length(nHidden)
        ip{h} = fp{h-1}*hiddenWeights{h-1};
        fp{h} = dropoutMask{h} .* tanh(ip{h});
    end
    yhat = Softmax(fp{end}*hiddenWeights{end});
    label = y(i);
    f = f - log(yhat(label));
    
    if nargout > 1
        % derivative:
        % -log(yhat(l)) = -yhat(l) + log(sum(exp(yhat)))
        % d/dy log(sum(exp(yhat))) = yhat
        backprop = yhat;
        backprop(label) = backprop(label) - 1;  % -log(yhat(l))

        for h = length(nHidden):-1:1
            gHidden{h} = gHidden{h} + fp{h}'*backprop;
            % calculate backpropgation for previous layer
            backprop = (backprop*hiddenWeights{h}').*sech(ip{h}).^2;
        end

        % Input Weights
        gInput = gInput + X(i,:)'*backprop;

    end
    
end

% Put Gradient into vector
if nargout > 1
    g = zeros(size(w));
    g(1:nVars*nHidden(1)) = gInput(:);
    offset = nVars*nHidden(1);
    for h = 2:length(nHidden)
        g(offset+1:offset+nHidden(h-1)*nHidden(h)) = gHidden{h-1};
        offset = offset+nHidden(h-1)*nHidden(h);
    end
    g(offset+1:offset+nHidden(end)*nLabels) = gHidden{end}(:);
end
