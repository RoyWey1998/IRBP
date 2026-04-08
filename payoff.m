% payoff function for nonlinear public goods game
function [pof] = payoff(R, nc, q, act)
c = 1;
if act == 1
    pof = R * c * (nc / 3)^q - c;
elseif act == 0
    pof = R * c * (nc / 3)^q;
end
end