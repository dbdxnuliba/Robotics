%Author: David Esteban Imnjoa Ruiz

function [Msubs, dynamicParamsReturn_, a] = getDynamicParameters(M,q, exceptionTerms_,parametricmethod_)
% Very empiric (/messy) method to extract dynamic parameters from the Inertia
% matrix in robot dynamics. Based on grouping terms.

% q = vector of q parameters (symbolic)
% q = [q1, q2, ... , qn]
% exceptionTerms: literals or expressions that are known and should be kept
% outside the dynamic parameters, like links length. 
% exceptionTerms = [l(2)] 

% created by Andr?s Arciniegas (06/2019)
%modified by David Esteban Imbajoa Ruiz 03 07 2021
exceptionTerms=[];
parametricmethod=1;
if(exist('exceptionTerms_'))
    if(exist('parametricmethod_'))
        if(2~=parametricmethod_)
            exceptionTerms=exceptionTerms_;
            
        else
                    parametricmethod=2;
        end
    else

    end
end
disp(">> Getting dynamic coefficients. Might take a while...")
[n,cols] = size(M); % square matrix
Msubs = M;
aa = sym('aa', [1,40],'real'); % 20 is a random approximation. Depends on M. For RR Robot is around 5
bbD = sym('bbD', [1,40],'real'); % 20 is a random approximation. Depends on M. For RR Robot is around 5
bbDvar=bbD;
posbbD=0;
dynamicParams = [];
nparams = 0; % Number of replacements
qallcomb=[];
excallcomb=[];

exTeleng=size(exceptionTerms,1);
exTeleng_=zeros(exTeleng,1);
% for kle=1:exTeleng%n for organizee similar parameters
%     excallcomb=[excallcomb,prod(nchoosek(exceptionTerms,kle),2)']; 
%     
% end
for ki=1:n%n for organizee similar parameters
    qallcomb=[qallcomb,sum(nchoosek(q,ki),2)']; 
    
end

qall_sincos_comb=[q',sin(qallcomb),cos(qallcomb)];
% qall_sincos_comb=[sin(qallcomb),cos(qallcomb)]; no factoriza q sin senos
for iter = 1:2
    % Get constants
    indepen = {};
    depen ={};
    dynParams = [];
    for k = 1:n % Main loop
        for j = k:cols
            dep=[]; % Independent terms
            indep=[]; % Coefficient of some q
            % expand is used to avoid (1/2)*(cos(q1) + cos(q2)) = 1 term. 
            % It has to be expanded
            
            % added by David imbajoa 4 9 2020 in order to improve the
            % factorizing part
%             [cxy, txy] = coeffs((collect(expand(Msubs(k,j)))),qall_sincos_comb , 'All');
%             childs=children(sum(cxy(:).*txy(:))+1);
            %
            %uncomment this line and coment the previus if it falls
            childs = children(expand(Msubs(k,j))+1); %% add 1 because it
%             if(sum(has(childs,exceptionTerms.*exceptionTerms))>0)
%                 disp("found cuadratic term");
%             end
%             has to be more than 1 term to split] 
            for i=1:length(childs)-1
                child = childs{i};
%                 if(has(child,exceptionTerms.*exceptionTerms))
%                     disp("found cuadratic term");
%                 end
                [child, keepGoing] = removeExceptionsInTerm(child, exceptionTerms, iter, nparams, aa);
                if ~keepGoing
                    continue
                end
                try

                if(has(child,q))
                    %if has(childs(i),cos(q))
                    if has(childs{i},cos(q))
                        for h =1:n % This is to deal with cases like m3*q3*cos(q2), where, if I replace directly 0 in cosine, the other q becomes zero too, making it all zero
                            if has(child,cos(q(h)))
                                child = subs(child,q(h),0) ;
                            end
                            
                            %by david test 1
                            if has(child,sin(q(h)))
                                child = subs(child,q(h),pi/2) ;
                            end
                            %endtest
                        end
                        
                        child = subs(child,q,ones(n,1)); % At this point it's free to replace by one
                        if child ~= 1 % In case we replace cosine and a '1' is left, discard it. (No coefficient)
                            dep = [dep, child];
                        end
                    elseif has(childs{i},sin(q))%has(childs(i),sin(q))
                        for h =1:n
                            if has(child,sin(q(h)))
                                child = subs(child,q(h),pi/2) ;
                            end
                        end
                        child = subs(child,q,ones(n,1)) ;
                        if child ~= 1 % should be 0, but we added a 1 element. In case we replace cosine and a one is left, discard it. (No coefficient)
                               dep = [dep, child]; 
                            end                      
                        else
                            child = subs(child,q,ones(n,1)) ;
                            dep = [dep, child];
                        end
                    else
                        indep = [indep, child];
                end
                    
                catch ME
   
                    rethrow(ME)

                end 
            end
            if length(dep) == 0 
                % These are dynamic coefficients for sure, since they
                % appear independently on the M matrix
                if sum(indep) ~= 0
                    dynParams = [dynParams, sum(indep)]   ; 
                end
            end
            depen = [depen, dep];
            indepen{k,j} = indep;
        end
    end
    % Totally independent terms are replaced by an 'a' term.
    % Also the coefficients of q dependent terms
    if iter == 1
        depenSubs = removeTermsSelfContained(depen);
        params = [dynParams depenSubs];
        if(~isempty(params))
            celparams= children(params+ ones(size(params)));
            if(~iscell(celparams))
                celparams={celparams};
            end
            %Selects only the parameters with only one term,
            params1term = cellfun(@length,celparams) <= 2;
            paramscell2=children(params(params1term))
            if(~iscell(paramscell2))
                paramscell2={paramscell2};
            end
            %Sort the parameters by length
            [~,I] = sort(cellfun(@length, paramscell2),'descend');
            params1 = params(params1term);
            %First put the composed parameters (m1+m2), and then the single
            %parameters terms (d*m3)
            params = [params(~params1term), params1(I)];
            
            nparams = length(params);
            dynamicParams = params;
            for i = 1:nparams
                %    dynamicParams = [dynamicParams params(i)];
                Msubs = subs(expand(Msubs), params(i), aa(i));
            end
            %             disp('MSubs First iteration')
            %             Msubs
        end
    end
    
    if iter == 2
        % Substitute independent variables
        indepSubs = [];
        for i = 1: numel(indepen)
            if length(indepen{i}) > 1
                indepSubs = [indepSubs, sum((indepen{i}))];
            end
        end
        %params = indepSubs;
        for i =1:length(indepSubs)
            indepTerm = subs(indepSubs(i), aa(1:nparams), dynamicParams); % Replace any 'aa' term previously assigned
            dynamicParams = [dynamicParams indepTerm];
            %%added by david
            Msubs = subs(expand(Msubs), indepSubs(i), aa(nparams+i));
            nparams=nparams+length(indepTerm); %% comentar esto creo ahah o ponte a rezar mejor ahah

        end
        disp('MSubs second iteration (before re-replacement)')
        Msubs
        % Finally, reorder the constants and assign the correct order to the
        % parameters.
        % This is done because they might have been replaced with another
        % 'a' term in the process. And some of them are not used anymore.
        disp("si falla uncomment this line verify  una lineas arriba")
        max_a = nparams;%+length(indepSubs); %%si falla uncomment this line
                
        dynamicParamsReturn = [];
        aa_replace = [];
                
        for kk = 1: max_a
            % If contains at least one term of that 'aa' element, save the
            % element
            if sum(has(Msubs, aa(kk)),'All') > 0 
                dynamicParamsReturn = [dynamicParamsReturn, dynamicParams(kk)];
                aa_replace = [aa_replace, aa(kk)];
            end
        end
        dynamicParamsReturn = dynamicParamsReturn.' ;% Vertical vector form
%         at = sym('at',[1, length(dynamicParamsReturn)],'real');
        
%         Msubs = subs(Msubs, aa_replace, at);
        Msubs = simplify(Msubs);
        
        chbuffer=[];

        for kt = 1:n % Main loop
            for jt = 1:cols
                [cxy, txy] = coeffs(simplify(collect(expand(Msubs(kt,jt)))),qall_sincos_comb , 'All');
                lparamd=cxy(:);
                txy_=txy(:);
                txy_=txy_(lparamd~=0)';
                txy_2=[];
                lparamd2=[];
                lparamd=lparamd(lparamd~=0)';
                for ier=1:size(lparamd,2)
                    tempglparamd=lparamd(ier);
                    tempgltxy_=txy_(ier);
                    if(exTeleng>0)
                        
                        
                        if(has(lparamd(ier),exceptionTerms))
                            tempdepval1=subs(tempglparamd,exceptionTerms,exTeleng_);
                            tempindepval1=tempglparamd-tempdepval1;
                            [ecxy, etxy] = coeffs(tempindepval1,exceptionTerms, 'All');%no he terminado esta aprte de momento funcona bien as?
                            tempglparamd=sum(ecxy(:).*etxy(:));
                            if(tempdepval1~=0)
                                posbbD=1+posbbD;
                                bbDvar(posbbD)=tempdepval1;
                                tempdepval1=bbD(posbbD);

                                tempglparamd(end+1)=tempdepval1;
                                tempgltxy_(end+1)=txy_(ier);
                            end
                        end
                    end
                    txy_2=[txy_2,tempgltxy_];
                    lparamd2=[lparamd2,tempglparamd];
                end
                
                lparamd=lparamd2;
                txy_=txy_2;
                Msubs(kt,jt)=sum(lparamd2.*txy_2);
                childsy=children(Msubs(kt,jt));
                for iba=1:size(lparamd,2)
                    fqtemp=lparamd(iba);
                    lfactmp=factor(fqtemp);
                    if(size(lfactmp,2)>1)
                        fqtemp_=1;
                        for fqtemp2= lfactmp
                            On_exceptionTerms=true;
                            if(exTeleng>0)
                                On_exceptionTerms=  ~has(fqtemp2,[exceptionTerms,q]);%%the last part si falla quitarlo y si tienes un dios reza para que funcione,xD. att: David
                            end
                            if(~isempty(symvar(fqtemp2))&&On_exceptionTerms)
                                
                                fqtemp_=fqtemp_*fqtemp2;
                                
                            end
                        end
                        lparamd(iba)=fqtemp_;
                    end
                end
                chbuffer=[chbuffer ,lparamd];
            end
        end
        [bbDunx,bbDuny,bbDunz]=unique(bbDvar(1:posbbD));
        old_bbD=bbD(bbDuny);
        Msubs = subs(Msubs, bbD(1:posbbD),old_bbD(bbDunz));
        chbuffer=subs(chbuffer,bbD(1:posbbD),old_bbD(bbDunz));
        dynamicParamsReturn_=simplify(subs(chbuffer,[old_bbD ],[bbDunx] ))';
        dynamicParamsReturn_=simplify(subs(dynamicParamsReturn_,[aa_replace ],[ dynamicParamsReturn' ] ));
        at = sym('at',[1, length(chbuffer)],'real');
        Msubs = subs(Msubs, chbuffer, at);
        [dynx,dyny,dynz]=unique(simplify(dynamicParamsReturn_.*dynamicParamsReturn_));
        old_at=at(dyny);
        a_ = sym('a_',[1, length(dynx)],'real');
%         a3 = sym('a',[1, length(dynx)],'real');

        dynx=dynamicParamsReturn_(dyny);
        
        %%detecting sign
        originalsigns=(dynamicParamsReturn_./dynx(dynz))';
        for isgnD=1:length(dynx)
            tempsignD=1;
            tempcoffD=coeffs(dynx(isgnD));
            if(isempty(symvar(tempcoffD(1)))&&length(tempcoffD)==1)
                tempsignD=sign(eval(tempcoffD(1)));
            end
%              tempsignD=1;
            dynx(isgnD)=tempsignD*dynx(isgnD);
            a_(isgnD)=tempsignD*a_(isgnD);
        end

    
        
%         Msubs = subs(Msubs, at, a_(dynz));%to fix the original sign
        Msubs = subs(Msubs, at,originalsigns.* a_(dynz));%to fix the original sign

        a_ = sym('a_',[1, length(dynx)],'real');%recover sign doens't work
        a = sym('a',[1, length(dynx)],'real');%recover sign doens't work

        dynx3z=1:length(dynx);
        if (parametricmethod==2)
            dynx2=subs(dynx,exceptionTerms_,ones(size(exceptionTerms_)));
            indexvalid=subs(dynx,exceptionTerms_,zeros(size(exceptionTerms_)))==0;
            
            %pivot
            dynx3=dynx;
            dynx3(indexvalid)=dynx2(indexvalid);
            
            [dynx2x,dynx2y,dynx2z]=unique(dynx3,'stable');
%             a3 = sym('a',[1, length(dynx2x)],'real');
            
            old_a=a_(dynx2y);%probar esto
            for ilo=1:length(dynx)
                 a3(1,ilo)=subs(dynx(ilo),dynx2(ilo),0);
                if( a3(1,ilo)==0)
                     a3(1,ilo)=subs(dynx(ilo),dynx2(ilo),old_a(dynx2z(ilo)));
                     New_dynamic(1,ilo)=dynx2(ilo);
                else
                    a3(1,ilo)=a_(ilo);
                    New_dynamic(1,ilo)=dynx(ilo);

                end
            end
            old_a2=subs(a3,exceptionTerms_,ones(size(exceptionTerms_)));

            [old2x,old2y,dynx3z]=unique(old_a2);
            old_a3=a_(old2y);
            a=sym('a',[1, length(old2x)],'real');
            dynx=New_dynamic(old2y)';%test this I don't know
            Msubs = subs(Msubs, a_, a3);
            
        end
        
        Msubs = subs(Msubs, a_, a(dynx3z));
        
        a=a';
        dynamicParamsReturn_=dynx;
    end
end

end
function [termReturn, keepGoing]= removeExceptionsInTerm(term, exceptionTerms, iteration, nparams, aa)
    % nparams = number of replaced parameters
    if iteration == 1
        termReturn = subs(term, exceptionTerms, ones(length(exceptionTerms),1)); % Replaces the exception terms by 1
        keepGoing = 1 ;% Even if there are replacements, the algorithm should continue
    end
    
    if iteration == 2 % Already passed by one replacement
        for hh = 1:nparams
            for xx = 1:length(exceptionTerms)
                % It should enter here only if the term has a variable that
                % has been replaced, and has exception term, like a4*l2.
                % This term should be kept just as it is.
                if(has(term,exceptionTerms(xx)))
                    %%added by david
                    term = subs(term, exceptionTerms, ones(length(exceptionTerms),1)); % Replaces the exception terms by 1
                    %%added by david
                    if(has(term,aa(hh))) %&& has(term,exceptionTerms(xx)))
                        keepGoing = 0; % No further replacements should be done with this term
                        termReturn = term; % Just to put some output, but not needed.
                        return
                    end
                end
            end
        end
        
        % if the loop ended, means that the term is ok, and should continue
        termReturn = term;
        keepGoing = 1;
        
        % Finally, the linear parametrization if found.
        %Ym = getLinearParametrization(
    end
    
%     for jj = 1:length(exceptionTerms)
% %         for ii = 1: length(subterms)
% %             if ~isequaln(subterms(ii),exceptionTerms(jj))
% %                 returnTerms = [returnTerms subterms(ii)]
% %             end
% %         end
%         returnTerms = [returnTerms deleteSymbolicTerm(subterms, exceptionTerms(jj))]
%     end
%     termReturn = prod(unique(returnTerms))
end

