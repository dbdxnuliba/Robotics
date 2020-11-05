% ====== Created by DAvid imbajoa 2019
% clc; clear;
% R = 'R';
% P = 'P';
% 
% qnum = 7; %Number of joints
%
%Sym values for depicting undefined variables in result. They can be
%numbers
% q = sym('q', [1 qnum]);
% d = sym('d', [1 qnum]);
% a = sym('a', [1 qnum]); 
%
% config = [R,R,P,R]
%SCARA Robot. Slide 09_DirectKinematics
% dh = [a(1) 0  d(1) q(1) ; 
%       a(2) 0  0 q(2);
%       0 0  q(3) 0;
%       0 pi d(4) q(4)];
%
%T = getJacobianF(dh,config) %Works fine.
%
% dhTable = dhddd
function [Jp, Jo,Jps, Jos] =getJacobianFromA(A,config,nmax)
dddd
disp("no funciona con machetaso mejor no fiarse, jacobian from transofrmation matrix")
    %First param tells the variable that starts the sequence
    %Must be defined in the order a - alpha - d - theta
    %Must initialize parameter before inserting
    
    % From Denavit-Hartemberg table to Homogeneous transform Matrix

    %qnum = 7; %Number of joints

    %Sym values for depicting undefined variables in result. They can be
    %numbers
    %q = sym('q', [1 qnum]);
    %d = sym('d', [1 qnum]);
    %a = sym('a', [1 qnum]); 
    config=upper(config);
    %Define symbolic variables
    alpha = sym('alpha');
    a =  sym('a'); 
    d = sym('d'); 
    theta =sym('theta');  
    
%     if ~exist('firstParam','var')
%      % third parameter does not exist, so default it to something
%       firstParam = 'a';
%      end    
%     if strcmp(firstParam,'a')
%         params = [a alpha d theta];
%     end
%     if strcmp(firstParam,'alpha')
%         params = [alpha a d theta];
%     end
%     
    joints = size(A,2); %Number of joints
    if(~exist('nmax'))
        nmax=joints;
    end
    %     A  = [cos(theta) -cos(alpha)*sin(theta) sin(alpha)*sin(theta)  a*cos(theta);...
    %           sin(theta) cos(alpha)*cos(theta) -sin(alpha)*cos(theta)  a*sin(theta);...
    %                 0     sin(alpha)            cos(alpha)              d          ;...
    %                 0               0                   0               1         ];
    
    %Loop row by row of DH table, calculating each matrix, storing in DH
%     for i = 1:joints
%         %         params1 = dhTable(i,:);
%         %         DH{i} = subs(A, params, params1);
%         DH{i}=A{i};
%     end
    %Chain multiplication
    DH=A;
    TMatAbs = eye(4);
    
    for i = 1:nmax
        TMatAbs = TMatAbs*DH{i};
        TMatRel{i} = TMatAbs;
    end
    TMatAbs = TMatAbs;
    
    Jp = sym(zeros(3,joints));
    Jo = sym(zeros(3,joints));
    z0 = [0 0 1].';
    p0 = [0 0 0].';
    fromwhen=0;%tomar fram cero en cuenta o no
    for i = 1:nmax
        if i > fromwhen%1
%             zi_1 = TMatRel{i}(1:3,3);%TMatRel{i-1}(1:3,3);
            zi_1 = TMatRel{i}(1:3,3);%TMatRel{i-1}(1:3,3);

        end
        if config(1,i) == 'P' || config(1,i) == 1 
            Jo(1:3,i) = zeros(3,1);
            if i == fromwhen%1
               Jp(1:3,i) = z0;
            else
               Jp(1:3,i) = zi_1;
            end
        end
        if config(1,i) == 'R' || config(1,i) == 0
            if i == 1
               Jp(1:3,i) = cross(z0,TMatAbs(1:3,4) - p0);
               Jo(1:3,i) = z0;
            else
               Jp(1:3,i) = cross(zi_1,TMatAbs(1:3,4) - TMatRel{i-1}(1:3,4));
               Jo(1:3,i) = zi_1;
            end
        end           
    end
    %Simplify result
    % put in horizontal vector form (12/06/2019)
    Jp = simplify(Jp);
    Jo = simplify(Jo);
    sincos_ = getShortNotation_SinCosV2(nmax);
    Jps = toShortNotation(Jp,sincos_);
    Jos = toShortNotation(Jo,sincos_);
end