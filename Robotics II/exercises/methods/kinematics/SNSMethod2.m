%author David Esteban Imbajoa Ruiz
function [qdotstar,W] = SNSMethod2(xdot,J,qN_Satured,Qdotmin,Qdotdmax)
disp("Assuming qN positive if it is not in this way comment this line  PAY ATTENTION!")
% qN_Satured=abs(qN_Satured)
if(~exist('Qdotmin'))
Qdotmin=-qN_Satured;
end 
if(~exist('Qdotdmax'))
Qdotdmax=qN_Satured;
end 
n=length(qN_Satured)
W=eye(n);
W_star=W;%% no s� aen d�nde va esto
qN_Satured_star=qN_Satured;%% no s� aen d�nde va esto
s=1;%current task scaled factor
s_star=0;%largest task scale factor so far
limit_exceeded=true;
numiter=0;
while limit_exceeded
    numiter=numiter+1;
    limit_exceeded=false;
    qdotstar=qN_Satured+pinv(J*W)*(xdot-J*qN_Satured);%antes de entrar en esta funci�n debe ser inicialzada con qdotstar=pinv(J)*xdot
        [maxvalue, maxindex] = max(abs(qdotstar)-abs(Qdotdmax));%q_dMaxTemp_)); % The positive values are violating the limit. We take the highest one. coloqu� Qdotmax pero no s� sie st� bien
    Violated_index=find(qdotstar>Qdotdmax|qdotstar<Qdotmin);
    Violatedvalue=false;
    if(~isempty(Violated_index))
        Violatedvalue=true
    end
    if (Violatedvalue ) % if there is an exceeding value
        limit_exceeded=true;
        disp("SNS Iterarion:  "+numiter)
        dnimss=digits();
        digits(4);
        disp("The valued that violate are:  "+ mat2str(string(Violated_index'))+"  with values:  "+mat2str(string(qdotstar(Violated_index)')));
        digits(dnimss);
        a=pinv(J*W)*xdot;
        b=qdotstar-a;
        [ ScalingFactor,MostCriticalJoint]=getTaskScalingFactor(a,b,n,Qdotmin,Qdotdmax);
        if(ScalingFactor>s_star)
            s_star=ScalingFactor;
            W_star=W;
            qN_Satured_star=qN_Satured;
        end
        j=MostCriticalJoint;
        W(j,j)=0;
        if(qdotstar(j)>Qdotdmax(j))
            qN_Satured(j)=Qdotdmax(j);
        end
        if(qdotstar(j)<Qdotmin(j))
            qN_Satured(j)=Qdotmin(j);
        end
        m=length(xdot);%I'm not sure about this part it is m dimention of the velocity or the rank
        %         if(rank(J*W)<m)
        if(rank(J*W)<rank(xdot))
            s=s_star;
            W=W_star;
            qN_Satured=qN_Satured_star;
            qdotstar=qN_Satured+pinv(J*W)*(s*xdot-J*qN_Satured);
            limit_exceeded=false;
            disp("the task couldn be completed check rank of JW or m tal vez lo calcul� mal ajaj")
        end
    end
    
    
    if(~limit_exceeded)
        disp('Result:')
        %         qdotstarFinal(originalpos)=qdotstar;
        
    end
    qdotstar
end


end
function [ ScalingFactor,MostCriticalJoint]=getTaskScalingFactor(a,b,n,Qdotmin,Qdotmax)
Smin=(Qdotmin-b)./(a);
Smax=(Qdotmax-b)./(a);
swithindex=find(Smin>Smax);
if(~isempty(swithindex))
    stemp=Smin(swithindex);
    Smin(swithindex)=Smax(swithindex);
    Smax(swithindex)=stemp;
end
s_max=min(Smax);
s_min=max(Smin);
[MostCriticalJointValue,MostCriticalJoint] =min(abs(Smax));
disp("Actual Most Critical Join is:  "+MostCriticalJoint);
ScalingFactor=s_max;
if(s_min>s_max||s_max<0||s_min>1)
ScalingFactor=0;
end
disp("Actual Scaling factor is:  "+string(ScalingFactor));

end




















