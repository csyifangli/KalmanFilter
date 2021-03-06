% Implementation of Ensemble filter
clear all;clc;close all;warning off;format bank;
rho_0 = 3.4e-3;
g = 32.2;
k_rho = 22000;
P_0 = diag([500 2*10^4 2.5*10^5]);
u_0 = [10^5;-6000;2000];
R_t = [0 0 0;0 2 0;0 0 0];
Q_t = 100;
H_t = [1 0 0];
tf=20;
dt=0.1;
t = 0.1:dt:tf;
n=size(u_0,1);
N = 30;
j=1;
% initial sample for truth simulation
x_t=[normrnd(10^5,sqrt(500));normrnd(-6000,sqrt(2*10^4));normrnd(2000,sqrt(2.5*10^5))];
tic 
for time=t
    % get the ensemble points
    if time == 0.1
        X = getensemble(u_0,P_0,N)
        for i=1:N
            X(:,i) = gmeanfunc(X(:,i),dt)+normrnd(0,sqrt(2));
        end
    else
        X = getensemble(s_u(:,j-1),P_t(:,:,j-1),N);
        for i=1:N
            X(:,i) = gmeanfunc(X(:,i),dt)+normrnd(0,sqrt(2));
        end
    end
    % find ensemble mean and covariance
    u_b(:,j) = (1/N)*X*ones(N,1);
    A = X - u_b(:,j)*ones(1,N);
    P_b(:,:,j) = A*A'/(N-1) +R_t*dt^2;
    
    % find the data terms
    %dynamics truth simulation
    x_t(:,j+1)= truthfunc(x_t(:,j),dt);
    
    % measurement value
    zm(j,:) = getensemble(x_t(1,j+1),100,N);
    % add noise to measurement
    for i=1:N
        D(i)=zm(j,i)+normrnd(0,sqrt(100));
    end
    X_p = X + P_b(:,:,j)*H_t'*inv(H_t*P_b(:,:,j)*H_t'+Q_t*dt^2)*(D-H_t*X);
    s_u(:,j) = (1/N)*X_p*ones(N,1);
    A_p = X_p - s_u(:,j)*ones(1,N);
    P_t(:,:,j) = A_p*A_p'/(N-1);
    j=j+1;
end
toc
plot(t,u_b(3,:))
% plot(t,(1/N)*zm*ones(N,1),'-b',t,s_u(1,:),'-r',t,u_b(1,:),'-g')
% plot(t,u_b(1,:))
legend('measured state','filtered state','Dynamics')
xlabel('Time (sec)');
ylabel('x1 (feet)');
function X = getensemble(m,v,N)
    X=[];dt=0.1;
    for i=1:N
        X=[X,mvnrnd(m',v)'];
    end
end

function snext = gmeanfunc(s,dt)
% function to propagate the dynamics
rho_0 = 3.4e-3;g = 32.2;
k_rho = 22000;
snext=zeros(3,1);
snext(1,1) = s(1) + s(2)*dt;
snext(2,1) = s(2) + dt*(-g+rho_0*exp(-s(1)/k_rho)*s(2)^2/(2*s(3)));
snext(3,1) = s(3);
end

function snextt = truthfunc(s,dt)
rho_0 = 3.4e-3;g = 32.2;
k_rho = 22000;
snextt=zeros(3,1);
snextt(1,1)=s(1) + s(2)*dt;
snextt(2,1)=s(2) + dt*(-g+rho_0*exp(-s(1)/k_rho)*s(2)^2/(2*s(3)) + normrnd(0,sqrt(2)));
snextt(3,1)=s(3);
end