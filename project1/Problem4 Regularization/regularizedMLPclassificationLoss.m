function [f,g] = regularizedMLPclassificationLoss(w,X,y,nHidden,nLabels,lambda)

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

% regularization
f = lambda * w'*w;
if nargout > 1
    gInput = 2*lambda * inputWeights;
    for h = 1:length(nHidden)
       gHidden{h} = 2*lambda * hiddenWeights{h}; 
    end
end

% Compute Output
for i = 1:nInstances
    ip{1} = X(i,:)*inputWeights;
    fp{1} = tanh(ip{1});
    for h = 2:length(nHidden)
        ip{h} = fp{h-1}*hiddenWeights{h-1};
        fp{h} = tanh(ip{h});
    end
    yhat = fp{end}*hiddenWeights{end};
    
    relativeErr = yhat-y(i,:);
    f = f + sum(relativeErr.^2);
    
    if nargout > 1
        backprop = 2*relativeErr;

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
