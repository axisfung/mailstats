%define _toProgPath     /opt/production
%define _mailModuleConfig 	%{_sysconfdir}/awstats
%define _tmppath 	/tmp
%define _cronDir 	%{_sysconfdir}/cron.d

Name:           mailstats
Version:        1.0.1
Release:        Base
Summary:        A program used to create mail statistics for email log
Group:          Applications/Internet
License:        GPL
URL:            NIL
Source0:        %{name}-%{version}.tar.gz
BuildArch:      noarch
BuildRoot:      %{BuildRoot}/%{name}-%{version}-%{release}-root
BuildRequires:  bash
Requires:       bash

%description
Mod by PY
Used for calcalute the simple statistics for the email service.
To install package into the /opt/production and /etc

%prep
%setup -q


%build

%install
rm -rf %{buildroot}
install -m 755 -d %{buildroot}/%{_toProgPath}/%{name}

tar cf - . | (cd "%{buildroot}/%{_toProgPath}/%{name}"; tar xfp -)
cp -rp %{buildroot}/%{_toProgPath}/%{name}/wwwroot/cgi-bin/awstats.model.conf %{buildroot}/%{_toProgPath}/%{name}/mpatch/awstats.mail.conf
patch %{buildroot}/%{_toProgPath}/%{name}/mpatch/awstats.mail.conf < %{buildroot}/%{_toProgPath}/%{name}/mpatch/awstats.mail.conf.patch
patch %{buildroot}/%{_toProgPath}/%{name}/wwwroot/cgi-bin/awstats.pl < %{buildroot}/%{_toProgPath}/%{name}/mpatch/awstats.patch
patch %{buildroot}/%{_toProgPath}/%{name}/tools/maillogconvert.pl < %{buildroot}/%{_toProgPath}/%{name}/mpatch/maillogconvert.patch

[[ ! -d %{buildroot}/%{_mailModuleConfig} ]] && %{__mkdir} -p "%{buildroot}/%{_mailModuleConfig}"
cp %{buildroot}/%{_toProgPath}/%{name}/mpatch/awstats.mail.conf %{buildroot}/%{_mailModuleConfig}
rm -rf "%{buildroot}/%{_toProgPath}/%{name}/mpatch"

cp %{buildroot}/%{_toProgPath}/%{name}/conf/httpd_conf.mailstats %{buildroot}/%{_mailModuleConfig}
#rm -rf "%{buildroot}/%{_toProgPath}/%{name}/conf"

[[ ! -d %{buildroot}/%{_cronDir} ]] && %{__mkdir} -p "%{buildroot}/%{_cronDir}"
cp %{buildroot}/%{_toProgPath}/%{name}/cron/mailstats.cron %{buildroot}/%{_cronDir}
#rm %{buildroot}/%{_toProgPath}/%{name}/cron/mailstats.cron && rmdir %{buildroot}/%{_toProgPath}/%{name}/cron

%pre
if [ "$1" = "1" ]; then
	if ! id opm >& /dev/null; then 
		%{_sbindir}/adduser opm -g 
		echo "opm" | passwd --stdin opm
	fi
fi

%post
echo "------------------------------------------------------------------"
echo "   %{name} Collection Scripts installed in %{_sysconfdir}"
echo "   %{name} Program installed in %{_toProgPath}/%{name}"
echo "   %{name} cron entries have been added to:"
echo "          %{_sysconfdir}/cron.d"
echo "   Some more extra work need to do "
echo "   1. Please remember to add configuration to httpd.conf"
echo "          Include %{_mailModuleConfig}/httpd_conf.mailstats"
echo "        or copy the file as mailstats.conf under /etc/httpd/conf.d/ manually"
echo "   2. Modify the syslogd to perform pre-action before maillog is rotated"
echo "   3. Rotate the maillog to have current year record only"
echo "------------------------------------------------------------------"


%clean
rm -rf %{buildroot}

%postun
if [ "$1" = "0" ]; then
        #Action is uninstallation, not called due to upgrade of a new package

        if [ -f %{_sysconfdir}/cron.d/mailstats.cron ]; then
                rm %{_sysconfdir}/cron.d/mailstats.cron
        fi

echo "-----------------------------------------------------------------"
echo "   Please clean up the modified file: "
echo "   1. Clean up the stats data under %{_toProgPath}"
echo "   2. Remove the following statement from httpd.conf"
echo "          Include /etc/awstats/httpd_conf.mailstats"
echo "-----------------------------------------------------------------"

fi


%files
%defattr(-,root,root,-)
%attr(755,opm,opm) %{_toProgPath}
%attr(600,root,root) %config(noreplace) %{_cronDir}/mailstats.cron
%attr(755,opm,opm) %config(noreplace) %{_mailModuleConfig}

%doc



%changelog
* Fri Mar 27 2015 Donald Fung <nil@pccw.com> 1.0
- Initial release

* Fri Mar 27 2015 Donald Fung <nil@pccw.com> 1.0.1
- Patching for better logging

