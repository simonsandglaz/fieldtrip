classdef mvmethod
% MVMETHOD base class for multivariate methods
%   
%   This base class contains common properties
%   which may be called by all child methods
%
%   mainly deals with data handling
%
%   Copyright (c) 2009, Marcel van Gerven


    properties
      
      verbose = false;
      
      params; % the used parameters for the mapping/unmapping
 
      % here we store some useful properties of training data and design

      indims    % data dimensions
      outdims   % design dimensions
      
    end
    
    methods                  
      
      function [m,desc] = getmodel(obj)
        % default behaviour when we ask for a model (override in subclass)
        
        if obj.verbose
          fprintf('don`t know how to return model for object of type %s; returning empty model and description\n',class(obj));
        end
        
        m = {};
        desc = {};
        
      end
      
      function obj = train(obj,data,design)
        
        if iscell(data) && ~obj.istransfer()
          
          params = cell(1,length(data));
          
          for c=1:length(data)
            obj = obj.train(data{c},design{c});
            params{c} = obj.params;
          end
          
          obj.params = params;
          
        else
          
          % data and design are collapsed to matrices
          if iscell(data) && obj.istransfer()
            
            if length(unique(cellfun(@(x)(size(x,2)),data))) > 1
            % check if datasets have the same number of features
              error('datasets must have the same number of features for transfer learning');
            end
              
            obj.indims = cell(1,length(data));
            for c=1:length(data)
              obj.indims{c} = size(data{c});
              data{c} = data{c}(1:size(data{c},1),:);
            end
            
            obj.outdims = cell(1,length(design));
            for c=1:length(design)
              obj.outdims{c} = size(design{c});
              design{c} = design{c}(1:size(design{c},1),:);
            end
            
          else
           
            obj.indims = size(data);
            data = data(1:size(data,1),:);
            
            obj.outdims = size(design);
            design = design(1:size(design,1),:);
          
          end
          
          obj.params = obj.estimate(data,design);
          
        end
      end
      
      function data = test(obj,data)
        
        if iscell(data) && ~obj.istransfer()
          
          params = obj.params;
          
          for c=1:length(data)
            
            obj.params = params{c};
            data{c} = obj.test(data{c});
          end
          
        else
          
          % data is collapsed to a matrix
          if iscell(data)
            for c=1:length(data)
              data{c} = data{c}(1:size(data{c},1),:);
            end
          else
            data = data(1:size(data,1),:);
          end
          
          data = obj.map(data);
          
          % try to map result back to original dimensions
          
          if iscell(data)
            for c=1:length(data)
              if numel(data{c}) == prod(obj.indims{c})
                data{c} = reshape(data{c},obj.indims{c});
              end
            end
          else
            if numel(data) == prod(obj.indims)
              data = reshape(data,obj.indims);
            end
          end
          
        end
        
      end
      
      function data = untest(obj,data)
        % invert the mapping
        
        if iscell(data) && ~obj.istransfer()
          
          params = obj.params;
          
          for c=1:length(data)
            
            obj.params = params{c};
            data{c} = obj.untest(data{c});
          end
          
        else
          
          % data is collapsed to a matrix
          if iscell(data)
            for c=1:length(data)
              data{c} = data{c}(1:size(data{c},1),:);
            end
          else
            data = data(1:size(data,1),:);
          end
          
          data = obj.unmap(data);
          
          % try to map result back to original dimensions
          
          if iscell(data)
            for c=1:length(data)
              if numel(data{c}) == prod(obj.indims{c})
                data{c} = reshape(data{c},obj.indims{c});
              end
            end
          else
            if numel(data) == prod(obj.indims)
              data = reshape(data,obj.indims);
            end
          end
          
        end
      end
      
      function X = unmap(obj,Y)
        % sometimes the inverse mapping does not exist
        
        error('inverse mapping does not exist for class %s',class(obj));
        
      end
      
      function b = istransfer(obj)
        % return whether or not this method is a transfer learner
        % must be overloaded by e.g., one_against_one
        
        if isa(obj,'transfer_learner')
          b = true;
        else
          b = false;
        end
      end
      
    end
    
    methods(Static=true)
      % some helper functions operating on datasets
      
      function Y = labeled(X)
        % return indices of labeled (non-nan) datapoints
        Y = find(any(~isnan(X(1:size(X,1),:)),2)); 
      end
      
      function Y = unlabeled(X)
        % return indices of unlabeled (nan) datapoints
        Y = find(any(isnan(X(1:size(X,1),:)),2)); 
      end
      
      function Y = unique(X)
        % return the unique trials
        Y = unique(X(1:size(X,1),:),'rows');
      end
      
      function n = nunique(X)
        % return the number of unique trials
        [tmp,tmp,idx] = unique(X(1:size(X,1),:),'rows');
        n = max(idx);
      end
            
    end
    
    methods(Abstract)
      
      Y = map(obj,X)   % mapping function
      p = estimate(X,Y); % parameter estimation
    end
    
end