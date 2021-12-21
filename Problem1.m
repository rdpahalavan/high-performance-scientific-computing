N=6; % Number of Grid points
np=4; % Number of workers
O=['A','B','C','D','E','F']; % Objects
M=2; % Number of steps

if isempty(gcp('nocreate'))
    parpool(np);
end

% Objects randomly placed in grid points
l = zeros(length(O),N)+78;
for i=1:length(O)
    k = 1;
    r = randi([1,N],1,1);
    while 1
        if l(k,r)==78
            l(k,r)=O(i);
            break;
        else
            k=k+1;
        end
    end
end

L = distributed(char(l));
spmd
    l = getLocalPart(L);
    lab = labindex();
    [u,v] = size(l);
    s = ceil(N/np);
    for m=1:M
        swapped=char.empty;
        fprintf("Step: %d\n",m);
        for i=1:s
            for ii=1:length(O)
                
                if i>v
                    c1='N';
                else
                    c1 = l(ii,i);
                end
                
                if c1~='N' && ~ismember(c1,swapped)
                               
                    r = randi([1,2],1,1); % flip a coin 1-Tail 2-Head
                    
                    if r == 1
                        fprintf("'%s' flipped the coin and gets: Tail\n",c1);
                        if i==1
                            destination=lab-1;
                            if destination==0
                                destination=np;
                            end
                            if v~=1
                                labSend(l(ii,i),destination); % labSend
                                fprintf("'%s' moved to Worker %d\n",l(ii,i),destination);
                                swapped=[swapped l(ii,i)];
                                l(ii,i)='N';
                            else
                                labSend(l(ii),destination); % labSend
                                fprintf("'%s' moved to Worker %d\n",l(ii),destination);
                                swapped=[swapped l(ii)];
                                l(ii)='N';
                            end
                        else
                            for j=1:length(O)
                                if l(j,i-1)=='N'
                                    l(j,i-1)=l(ii,i);
                                    fprintf("'%s' moved to Left within the Worker\n",l(ii,i));
                                    swapped=[swapped l(ii,i)];
                                    l(ii,i)='N';
                                    break;
                                end
                            end
                        end
 
                    end
                    
                    if r == 2
                        fprintf("'%s' flipped the coin and gets: Head\n",c1);
                        if i==v
                            destination=lab+1;
                            if destination==np+1
                                destination=1;
                            end
                            if v~=1
                                labSend(l(ii,i),destination); % labSend
                                fprintf("'%s' moved to Worker %d\n",l(ii,i),destination);
                                swapped=[swapped l(ii,i)];
                                l(ii,i)='N';
                            else
                                labSend(l(ii),destination); % labSend
                                fprintf("'%s' moved to Worker %d\n",l(ii),destination);
                                swapped=[swapped l(ii)];
                                l(ii)='N';
                            end
                                
                        else
                            for j=1:length(O)
                                if l(j,i+1)=='N'
                                    l(j,i+1)=l(ii,i);
                                    fprintf("'%s' moved to Right within the Worker\n",l(ii,i));
                                    swapped=[swapped l(ii,i)];
                                    l(ii,i)='N';
                                    break;
                                end
                            end
                        end
                    end
                    
                end
                
                labBarrier; % labBarrier
                isDataAvail = labProbe; % labProbe
                
                if isDataAvail
                    [data,srcWkrIdx,tag] = labReceive; % labReceive
                    if ~ismember(data,swapped)
                        swapped=[swapped data];
                    end
                    if v~=1
                        if srcWkrIdx==1 && lab==np
                            for j=1:length(O)
                                if l(j,v)=='N'
                                    l(j,v)=data;
                                    break;
                                end
                            end
                        elseif srcWkrIdx==np && lab==1
                            for j=1:length(O)
                                if l(j,1)=='N'
                                    l(j,1)=data;
                                    break;
                                end
                            end
                        elseif srcWkrIdx>lab
                            for j=1:length(O)
                                if l(j,v)=='N'
                                    l(j,v)=data;
                                    break;
                                end
                            end
                        else
                            for j=1:length(O)
                                if l(j,1)=='N'
                                    l(j,1)=data;
                                    break;
                                end
                            end
                        end
                    else
                        for j=1:length(O)
                            if l(j)=='N'
                                l(j)=data;
                                break;
                            end
                        end
                    end
                end
                
            end
        end
    end
end

X = gather(l);

initial_pos = zeros(length(O),2);
final_pos = zeros(length(O),2);
Z = char.empty;

for i=1:np
    Z = [Z, X{i}];
end
for i=1:length(O)
    o = O(i);
    [x,y] = find(L==o);
    initial_pos(i,1)=x;
    initial_pos(i,2)=y;
    [x,y] = find(Z==o);
    final_pos(i,1)=x;
    final_pos(i,2)=y;
end

% Plot Initial and Final positions

figure;
for i=1:length(O)
    scatter(initial_pos(i,2),initial_pos(i,1),75,'filled');
    hold on;
end
title('Initial Positions');
xlabel('Grid Point');
legend('A','B','C','D','E','F');

figure('Name','Final Positions');
for i=1:length(O)
    scatter(final_pos(i,2),final_pos(i,1),75,'filled');
    hold on;
end
title('Final Positions');
xlabel('Grid Point');
legend('A','B','C','D','E','F');

poolobj = gcp('nocreate');
delete(poolobj);