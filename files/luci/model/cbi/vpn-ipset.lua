local m, s, o
local uci = luci.model.uci.cursor()

m = Map("vpn-ipset", translate("VPN IPset"), translate("IPset based VPN rules (with dnsmasq support)."))

-- [[ General settings ]] --
s = m:section(TypedSection, "general", translate("Basic Settings"))
s.anonymous = true
-- s.addremove = true

o = s:option(Flag, "enabled", translate("Enable"))

o = s:option(Value, "ipset_name", translate("IPset Name"), translate("{name}_v4 and {name}_v6 will be created for Ipv4 and IPv6."))
o.optional = false
o.rmempty = true

o = s:option(Value, "interface", translate("Network Interface"), translate("Routing traffic to this interface by using iproute2 and iptables."))
o:value("_nil_", translate("Disable"))
uci:foreach("network", "interface", function(section)
    local name = section[".name"]
    local ifname = uci:get("network", name, "ifname") or name
    local proto = uci:get("network", name, "proto")
    o:value(ifname, string.format("%s (%s)", ifname, proto))
end)
o.default = "_nil_"
o.rmempty = false

o = s:option(DynamicList, "ip_addresses", translate("IP Addresses"), translate("Adding the above IP addresses into IPset."))
o.datatype = "ipaddr"
o.rmempty = true


-- [[ IPset Rules for DNSMASQ]] --
s = m:section(TypedSection, "dnsmasq_ipset", translate("DNSMASQ IPset Settings"), translate("Auto-update from provided URLs at 04:04 every day."))
s.anonymous = true

o = s:option(DynamicList, "dns_servers", translate("DNS servers"), translate("e.g. 127.0.0.1#5300 or ::1#5300 (port is not required)."))
o.rmempty = true

o = s:option(DynamicList, "domains", translate("Domains"), translate("Adding above domains to dnsmasq ipset."))
o.datatype = "host"
o.size = 128
o.rmempty = true

o = s:option(DynamicList, "gfwlist_urls", translate("GFWList URLs"), translate("https://github.com/gfwlist/gfwlist"))
o.placeholder = "e.g. https://exam.ple.com/gfwlist.txt"
-- o.size = 128
o.rmempty = true

o = s:option(DynamicList, "domainslist_urls", translate("Domains URLs"), translate("Format: one domain per line"))
o.placeholder = "e.g. https://exam.ple/domains.txt"
-- o.size = 128
o.rmempty = true


-- https://github.com/openwrt/luci/wiki/LuCI-0.10
function m.on_after_commit(self)
    -- XXX(damnever): maybe there is a cache problem, so the delayed_reload
    -- command will run in background with `sleep 10`.
    luci.sys.call("/etc/init.d/vpn-ipset delayed_reload")
end
return m
