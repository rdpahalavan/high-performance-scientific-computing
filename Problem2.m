% Initial Money = [Dealer Player1 Player2 Player3]
money_initial = [100 20 20 20];

if isempty(gcp('nocreate'))
    parpool(4); % Starting 4 workers
end

money = distributed(money_initial);

spmd
    lab = labindex();
    my_money = getLocalPart(money);
    money_stat(1,1)=0;
    money_stat(1,2)=my_money;
    bankrupt=0;
    
    for bet_round=1:20 % Number of rounds
        if ~bankrupt
            fprintf("Round %d Starts...\n",bet_round);
        end
       
        if lab~=1
            
            if ~bankrupt
                if bet_round==1
                    my_bet = randi([1,my_money],1,1); % Initial bet by players
                else
                    my_bet=round(my_money*0.5);
                end
                my_money = my_money-my_bet;
                labSend(my_bet,1);
            else
                labSend(0,1);
            end
        end

        if lab==1
                d2 = labReceive(2);
                d3 = labReceive(3);
                d4 = labReceive(4);
            
            D = [0 d2 d3 d4];

            for i=2:4
                
                if D(i)~=0
                    
                    if bet_round==1
                        my_bet = randi([1,round(my_money/2)],1,1); % Initial bet by dealer
                    else
                        my_bet = round(0.25*my_money);
                    end
                    my_money = my_money-my_bet;
                    fprintf("Player %d bet $%d and Dealer bet $%d\n",i,D(i),my_bet);
                    r = randi([1,2],1,1); % 1-Dealer Win, 2-Player Win
                    if r==1
                        my_money = my_money + my_bet + D(i);
                        fprintf("Dealer won $%d\n\n",D(i));
                        labSend(0,i);
                    else
                        fprintf("Player %d won $%d\n\n",i,my_bet);
                        labSend(my_bet+D(i),i);
                    end
                end
                
            end
        else
            if ~bankrupt
                d = labReceive(1);
                my_money = my_money + d;
            end
        end
        
        if ~bankrupt
            fprintf("Amount Remaining at end of Round %d: $%d\n",bet_round,my_money);
            money_stat(bet_round+1,1)=bet_round;
            money_stat(bet_round+1,2)=my_money;
        end
        
        if lab==1 && my_money<=4
            bankrupt=1;
            labSend(1,2);
            labSend(1,3);
            labSend(1,4);
        elseif lab~=1 && my_money<1
            bankrupt=1;
        end
        
        labBarrier;
        
        if lab==1
            if bankrupt
                break;
            end          
        else
            isDataAvail = labProbe(1);
            if isDataAvail
                e=labReceive(1);
                if e==1
                    break;
                end
            end
        end
                
    end
end

% Plot the outcomes

a=money_stat{1};
figure;
plot(a(:,1),a(:,2),'LineWidth',2);
title("Dealer");
xlabel("Round");
ylabel("Money");

b=money_stat{2};
figure;
plot(b(:,1),b(:,2),'LineWidth',2);
title("Player 1");
xlabel("Round");
ylabel("Money");

c=money_stat{3};
figure;
plot(c(:,1),c(:,2),'LineWidth',2);
title("Player 2");
xlabel("Round");
ylabel("Money");

d=money_stat{4};
figure;
plot(d(:,1),d(:,2),'LineWidth',2);
title("Player 3");
xlabel("Round");
ylabel("Money");