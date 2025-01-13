iptables -t mangle -A PREROUTING -m conntrack --ctstate INVALID -j DROP
iptables -t mangle -A PREROUTING -p tcp ! --syn -m conntrack --ctstate NEW -j DROP
iptables -t mangle -A PREROUTING -p tcp -m conntrack --ctstate NEW -m tcpmss ! --mss 536:65535 -j DROP
iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j DROP
iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN FIN,SYN -j DROP
iptables -t mangle -A PREROUTING -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,RST FIN,RST -j DROP
iptables -t mangle -A PREROUTING -p tcp --tcp-flags FIN,ACK FIN -j DROP
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,URG URG -j DROP
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,FIN FIN -j DROP
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ACK,PSH PSH -j DROP
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL ALL -j DROP
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL NONE -j DROP
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL FIN,PSH,URG -j DROP
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL SYN,FIN,PSH,URG -j DROP
iptables -t mangle -A PREROUTING -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP
iptables -t mangle -A PREROUTING -p icmp -j DROP
iptables -A INPUT -p tcp -m connlimit --connlimit-above 80 -j REJECT --reject-with tcp-reset
iptables -A INPUT -p tcp -m conntrack --ctstate NEW -m limit --limit 60/s --limit-burst 20 -j ACCEPT
iptables -A INPUT -p tcp -m conntrack --ctstate NEW -j DROP
iptables -t mangle -A PREROUTING -f -j DROP
iptables -A INPUT -p tcp --tcp-flags RST RST -m limit --limit 2/s --limit-burst 2 -j ACCEPT
iptables -A INPUT -p tcp --tcp-flags RST RST -j DROP
iptables -I INPUT -m geoip --src-cc KR -p tcp -m multiport --dports 1201,1202,1203,1204,1205,1206,1207,1208,1209,1210 -j ACCEPT
ipset create blacklist hash:ip maxelem 4294967295;
iptables -t raw -A PREROUTING -m set --match-set blacklist src -j DROP
for port in {1201..1210}; do
    iptables -t mangle -A PREROUTING -p tcp --dport $port -m connlimit --connlimit-above 4 -j SET --add-set blacklist src
    iptables -t mangle -A PREROUTING -p tcp --dport $port -m connlimit --connlimit-above 4 -j DROP
    iptables -t mangle -A PREROUTING -p tcp -m tcp --dport $port -m conntrack --ctstate NEW -m hashlimit --hashlimit-above 3/sec --hashlimit-burst 7 --hashlimit-mode srcip --hashlimit-name connection_flood --hashlimit-htable-expire 3 -j SET --add-set blacklist src
    iptables -t mangle -A PREROUTING -p tcp -m tcp --dport $port -m conntrack --ctstate NEW -m hashlimit --hashlimit-above 3/sec --hashlimit-burst 7 --hashlimit-mode srcip --hashlimit-name connection_flood --hashlimit-htable-expire 3 -j DROP
done
