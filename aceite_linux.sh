#!/bin/bash

##########################################################################################################
##########################################################################################################
####                                                                                                  ####
####                            Script de aceite  zabbix/salt/ldap                                    ####
####                                                                                                  ####
####                            Criado por Alexandre Malaquias                                        ####
####                            Data: 20/07/2022                                                      ####
####                            v1.2: 07/08/2022                                                      ####
####                                                                                                  ####
####                            S.Os Homologados:                                                     ####
####                            Centos/RHEL releases 6,7 e 8                                          ####
####                                                                                                  ####
####                            Pre requisitos:                                                       ####
####                            Comunicação com repositorio empresa 200.185.180.109                     ####
####                            Regras de firewall para zabbix/salt/ldap                              ####
####                                                                                                  ####
##########################################################################################################
##########################################################################################################


######################################## Variaveis globais ###############################################

so_version=$(cat /etc/system-release | awk -F '.' '{print$1}')
zabbix_rhel_path='http://200.185.180.109/linux/zabbix/5.2/rhel/'
salt_path='http://200.185.180.109/files/saltstack/install-saltminion.sh'

##Repositorios
repo_centos6='http://200.185.180.109/repo_rpms/centos6-release-empresa-x86_64.rpm'
repo_centos7='http://200.185.180.109/repo_rpms/centos7-repos-1-latest.el7.noarch.rpm'
repo_centos8='http://200.185.180.109/repo_rpms/centos8-repos-1-latest.el8.noarch.rpm'
repo_rhel6='http://200.185.180.109/repo_rpms/redhat6-release-empresa-x86_64.rpm'
repo_rhel7='http://200.185.180.109/repo_rpms/redhat7-repos-1-latest.el7.noarch.rpm'
repo_rhel8='http://200.185.180.109/repo_rpms/redhat8-repos-1-latest.el8.noarch.rpm'


#### Teste laboratorio
#repo_centos7='http://192.168.239.254/pacotes/centos7-repos-1-latest.el7.noarch.rpm'


#########################################################################################################

banner_conf(){
echo
echo "Digite o nome do cliente:"
echo
read cliente
echo


if [ -f /usr/local/bin/dynmotd ]
        then
                echo "/usr/local/bin/dynmotd já existe"
                exit
        else
                cat <<\EOF> /usr/local/bin/dynmotd
#!/bin/bash

##################  VARIAVEIS DO AMBIENTE #######################

HOSTNAME=`uname -n`
MEMORY_FREE=`free -mt | grep -i mem | awk '{print $3;}'`
MEMORY_TOTAL=`free -mt | grep -i mem | awk '{print $2;}'`
MEM_POR=$(($MEMORY_FREE*100/$MEMORY_TOTAL))
PSA=`ps -Afl | wc -l`
uptime=`cat /proc/uptime | cut -f1 -d.`
upDays=$((uptime/60/60/24))
upHours=$((uptime/60/60%24))
upMins=$((uptime/60%60))
LOAD1=`cat /proc/loadavg | awk {'print $1'}`
LOAD5=`cat /proc/loadavg | awk {'print $2'}`
LOAD15=`cat /proc/loadavg | awk {'print $3'}`

###########################################################

if [ $MEM_POR -gt 90 ];
then
        MEM_POR_COLOR=$(tput setaf 1; echo -e ${MEM_POR}%; tput sgr0)

else
        MEM_POR_COLOR=$(tput setaf 2; echo -e ${MEM_POR}%; tput sgr0)
fi

tput setaf 3; tput bold; echo "
==========================================================================================

 - Hostname do sistema ............: $HOSTNAME
 - Versão do sistema   ............: `cat /etc/os-release  | grep -i pret | awk -F '"' '{print$2}'`
 - Usuários conectados ............: Atualmente `users | wc -w` usuário(s)

==========================================================================================

 - Utilização do Processador   ......: $LOAD1, $LOAD5, $LOAD15 (1, 5, 15 min)
 - Utilização da SWAP          ......: `free -m | tail -n 1 | awk '{print $3}'` MB
 - Processos em execução       ......: $PSA processos rodando
 - Tempo Online do sistema     ......: $upDays dia(s) $upHours hora(s) $upMins minuto(s)
 - Utilização de Memoria em %  ......: $MEM_POR_COLOR
==========================================================================================
"
EOF

chmod +x /usr/local/bin/dynmotd

fi


grep dynmotd /etc/profile > /dev/null 2>/dev/null
if [ $? -eq 0 ]
        then
                echo "/etc/profile esta configurado!"
                exit
        else
                cat <<\EOF>> /etc/profile
###
## LOG DE COMANDOS NO SYSLOG
####
PORT=`who am i | awk '{ print $5 }' | sed 's/(//g' | sed 's/)//g'`
logger -p local5.notice -t "bash $LOGNAME $$" User $LOGNAME logged from $PORT
function history_to_syslog
{
declare cmd
declare p_dir
declare LOG_NAME
cmd=$(history 1)
p_dir=$(pwd)
LOG_NAME=$(echo $LOGNAME)
logger -p local5.notice -- SESSION = $$, from_remote_host = $PORT, USER = $LOG_NAME, PWD=$p_dir, CMD =$cmd
}
trap history_to_syslog DEBUG || EXIT
export HISTTIMEFORMAT='%F %T '
/usr/local/bin/dynmotd
EOF
fi

cat /etc/rsyslog.conf | grep -i "local5.notice"  > /dev/null 2>/dev/null
if [ $? -eq 0 ]
        then
                echo "/etc/rsyslog.conf esta configurado!"
        else
                cat <<\EOF>>/etc/rsyslog.conf
## LOG DE COMANDOS NO SYSLOG
#
local5.notice                                           /var/log/cmd.log
EOF
fi

cat /etc/profile | grep -i $cliente  > /dev/null 2>/dev/null
if [ $? -eq 0 ]
        then
                echo
        else
                cat <<EOF>> /etc/profile
PS1="[\[\033[0;31m\]$cliente\[\e[0m\]][\u@\h][\W]\\$ "
EOF
fi



cat /etc/bashrc | grep -i $cliente  > /dev/null 2>/dev/null
if [ $? -eq 0 ]
        then
                echo "/etc/bashrc esta configurado!"
        else
                cat <<EOF>> /etc/bashrc
PS1="[\[\033[0;31m\]$cliente\[\e[0m\]][\u@\h][\W]\\$ "
EOF
fi

if [ ! -f /etc/logrotate.d/syslog ]
        then
                cat <<\EOF> /etc/logrotate.d/syslog
/var/log/cron
/var/log/maillog
/var/log/messages
/var/log/secure
/var/log/spooler
/var/log/cmd.log
{
    missingok
    sharedscripts
    postrotate
        /bin/kill -HUP `cat /var/run/syslogd.pid 2> /dev/null` 2> /dev/null || true
    endscript
}
EOF
fi

echo "Banner configurado com sucesso!"

}



install_repo_empresa(){

case $so_version in
        "Red Hat Enterprise Linux Server release 6")
                        rpm -qa|  grep -i empresa|grep -i repo > /dev/null
                        if [ $? -eq 0 ]
                                then
                                        echo "Pacote do repositorio empresa rhel6 instalado!"
                                        exit
                                else
                                        backup_dir_repo=bkp_`date +%F_%H:%M`
                                        mkdir -p /etc/yum.repos.d/$backup_dir_repo
                                        mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/$backup_dir_repo 2>/dev/null
                                        rpm -i  $repo_rhel6 --quiet 2>/dev/null
                                        if [ $? -eq 0  ]
                                                then
                                                        echo "Iniciando a instalacao do repositorio empresa - $so_version"
                                                else
                                                        echo "Problemas na instalacao do pacote - $so_version"
                                                        exit
                                        fi

                        fi ;;

                           "CentOS Linux release 6"|"CentOS release 6")
                        rpm -qa|  grep -i empresa | grep -i repo> /dev/null
                        if [ $? -eq 0 ]
                                then
                                        echo "Pacote do repositorio empresa centos6 instalado!"
                                        exit
                                else
                                        backup_dir_repo=bkp_`date +%F_%H:%M`
                                        mkdir -p /etc/yum.repos.d/$backup_dir_repo
                                        mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/$backup_dir_repo  2>/dev/null
                                        rpm -i  $repo_centos6 --quiet 2>/dev/null
                                        if [ $? -eq 0  ]
                                                then
                                                        echo "Iniciando a instalacao do repositorio empresa - $so_version"
                                                else
                                                        echo "Problemas na instalacao do pacote - $so_version"
                                                        exit
                                        fi

                        fi ;;

        "Red Hat Enterprise Linux Server release 7")
                        rpm -qa|  grep -i empresa | grep -i repo> /dev/null
                        if [ $? -eq 0 ]
                                then
                                        echo "Pacote do repositorio empresa rhel7 instalado!"
                                        exit
                                else
                                        backup_dir_repo=bkp_`date +%F_%H:%M`
                                        mkdir -p /etc/yum.repos.d/$backup_dir_repo
                                        mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/$backup_dir_repo  2>/dev/null
                                        rpm -i  $repo_rhel7 --quiet 2>/dev/null
                                        if [ $? -eq 0  ]
                                                then
                                                        echo "Iniciando a instalacao do repositorio empresa - $so_version"
                                                else
                                                        echo "Problemas na instalacao do pacote - $so_version"
                                                        exit
                                        fi

                        fi ;;

        "CentOS Linux release 7")
                        rpm -qa|  grep -i empresa | grep -i repo> /dev/null
                        if [ $? -eq 0 ]
                                then
                                        echo "Pacote do repositorio empresa centos7 instalado!"
                                        exit
                                else
                                        backup_dir_repo=bkp_`date +%F_%H:%M`
                                        mkdir -p /etc/yum.repos.d/$backup_dir_repo
                                        mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/$backup_dir_repo  2>/dev/null
                                        rpm -i  $repo_centos7 --quiet 2>/dev/null
                                        if [ $? -eq 0  ]
                                                then
                                                        echo "Iniciando a instalacao do repositorio empresa - $so_version"
                                                else
                                                        echo "Problemas na instalacao do pacote - $so_version"
                                                        exit
                                        fi

                        fi ;;

        "Red Hat Enterprise Linux Server release 8")
                        rpm -qa|  grep -i empresa | grep -i repo> /dev/null
                        if [ $? -eq 0 ]
                                then
                                        echo "Pacote do repositorio empresa rhel8 instalado!"
                                        exit
                                else
                                        backup_dir_repo=bkp_`date +%F_%H:%M`
                                        mkdir -p /etc/yum.repos.d/$backup_dir_repo
                                        mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/$backup_dir_repo  2>/dev/null
                                        rpm -i  $repo_rhel8 --quiet 2>/dev/null
                                        if [ $? -eq 0  ]
                                                then
                                                        echo "Iniciando a instalacao do repositorio empresa - $so_version"
                                                else
                                                        echo "Problemas na instalacao do pacote - $so_version"
                                                        exit
                                        fi

                        fi ;;

        "CentOS Linux release 8")
                        rpm -qa|  grep -i empresa| grep -i repo > /dev/null
                        if [ $? -eq 0 ]
                                then
                                        echo "Pacote do repositorio empresa centos8 instalado!"
                                        exit
                                else
                                        backup_dir_repo=bkp_`date +%F_%H:%M`
                                        mkdir -p /etc/yum.repos.d/$backup_dir_repo
                                        mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/$backup_dir_repo  2>/dev/null
                                        rpm -i  $repo_centos8 --quiet 2>/dev/null
                                        if [ $? -eq 0  ]
                                                then
                                                        echo "Iniciando a instalacao do repositorio empresa - $so_version"
                                                else
                                                        echo "Problemas na instalacao do pacote - $so_version"
                                                        exit
                                        fi

                        fi ;;
esac

grep -iE 'mirror.empresa.com' /etc/hosts >/dev/null 2>/dev/null
if [ $? -eq 0 ]
        then
                echo "Endereço mirror.empresa.com configurado no /etc/hosts!"
                echo
        else
                cat <<EOF >> /etc/hosts

###REPO empresa
200.185.180.109 mirror.empresa.com

EOF

fi

if [ $? -eq 0 ]
        then
                echo "Repositorio instalado com sucesso"
        else
                echo "Problemas na instalacao do repositorio"
fi

}

#########################################################################################################

install_zabbix(){
rpm -qa|  grep -i zabbix >/dev/null
    if [ $? -eq 0 ]
    then
        echo "Zabbix já está instalado!!!"
        exit
    else
        echo "Instalando Zabbix Agent:"
        echo
        case $so_version in
        "Red Hat Enterprise Linux Server release 6"|"CentOS Linux release 6"|"CentOS release 6")
                echo "Instalando agent para centos/rhel 6"
                echo
                rpm -i  $zabbix_rhel_path/6/x86_64/zabbix-agent-5.2.6-1.el6.x86_64.rpm --quiet 2>/dev/null
                if [ $? -eq 0 ]
                        then
                                echo "Zabbix $so_version instalado com sucesso!"
                        else
                                echo "Problemas na instalacao do zabbix $so_version"
                                exit

                fi
                ;;
        "Red Hat Enterprise Linux Server release 7"|"CentOS Linux release 7")
                echo "Instalando agent para centos/rhel 7"
                echo
                rpm -i  $zabbix_rhel_path/7/x86_64/zabbix-agent-5.2.6-1.el7.x86_64.rpm --quiet 2>/dev/null
                if [ $? -eq 0 ]
                        then
                                echo "Zabbix $so_version instalado com sucesso!"
                        else
                                echo "Problemas na instalacao do zabbix $so_version"
                                exit

                fi
                ;;
        "Red Hat Enterprise Linux Server release 8"|"CentOS Linux release 8")
                echo "Instalando agent para centos/rhel 8"
                echo
                rpm -i  $zabbix_rhel_path/8/x86_64/zabbix-agent-5.2.6-1.el8.x86_64.rpm --quiet 2>/dev/null
                if [ $? -eq 0 ]
                        then
                                echo "Zabbix $so_version instalado com sucesso!"
                        else
                                echo "Problemas na instalacao do zabbix $so_version"
                                exit

                fi
                ;;
        esac
    fi
echo

echo "-------------------- Configurando zabbix agent: --------------------"
echo
echo "Digite o endereco do Zabbix Master/Proxy:"
read zabbix_master
echo

cp /etc/zabbix/zabbix_agentd.conf /etc/zabbix/zabbix_agentd.conf_`date +%F_%H:%M`_bkp

cat  <<EOF > /etc/zabbix/zabbix_agentd.conf
PidFile=/var/run/zabbix/zabbix_agentd.pid
LogType=file
LogFile=/var/log/zabbix/zabbix_agentd.log
LogFileSize=5
Server=$zabbix_master
ServerActive=$zabbix_master
HostMetadataItem=system.uname
RefreshActiveChecks=120
BufferSend=5
EOF

        case $so_version in
        "Red Hat Enterprise Linux Server release 6"|"CentOS Linux release 6"|"CentOS release 6")
                /etc/init.d/zabbix-agent start > /dev/null 2>/dev/null
                chkconfig zabbix-agent on > /dev/null 2>/dev/null
                ;;
        "Red Hat Enterprise Linux Server release 7"|"CentOS Linux release 7")
                systemctl start zabbix-agent > /dev/null 2>/dev/null
                systemctl enable zabbix-agent > /dev/null 2>/dev/null
                ;;
        "Red Hat Enterprise Linux Server release 8"|"CentOS Linux release 8")
                systemctl start zabbix-agent > /dev/null 2>/dev/null
                systemctl enable zabbix-agent > /dev/null 2>/dev/null
                ;;
        esac

echo "Zabbix agent instalado com sucesso!"
}

#########################################################################################################

install_salt(){
rpm -qa|  grep -i salt-minion >/dev/null
    if [ $? -eq 0 ]
    then
        echo "Salt Minion já está instalado!!!"
        exit
    else
        echo "Instalando Salt Minion:"
        echo
        echo "Digite o CID:"
        read salt_cid
        echo
        echo "Digite o Master:"
        read salt_sindic
        echo
        curl -O $salt_path 2>/dev/null
        chmod +x install-saltminion.sh 2>/dev/null
        ./install-saltminion.sh --cid $salt_cid --salt-syndic $salt_sindic 2>/dev/null
        rm -f install-saltminion.sh 2>/dev/null
    fi
echo
}


#########################################################################################################

install_sssd(){
#### Validacao do servico SSSD no arquivos

ps aux | grep -iE 'sssd|nscd|nslcd' | grep -v grep >/dev/null 2>/dev/null
if [ $? -eq 0 ]
        then
                echo
                echo "---------------------------- Algum DEAMON LDAP rodando, validar as conf ---------------------------"
                echo
                exit
        else
                echo
                echo "----------------------------------- Iniciando a conf LDAP SSSD ------------------------------------"
                echo
fi

#### Backup dos arquivos alterados

cp /etc/nsswitch.conf /etc/nsswitch.conf-bkp_`date +%F_%H-%M`
cp /etc/hosts /etc/hosts-bkp`date +%F_%H-%M`
cp /etc/sudoers /etc/sudoers-bkp_`date +%F_%H-%M`

##### Instalacao dos pacotes necessarios

yum install openldap-clients sssd sssd-ldap oddjob-mkhomedir -y  >/dev/null 2>/dev/null

##### Criacao do certificado

if [ -d /etc/openldap/cacerts ]
        then
                echo "------------------------------ Diretorio de certificados ja criado --------------------------------"
                echo
        else
                mkdir -p /etc/openldap/cacerts
                chmod 600 /etc/openldap/cacerts
fi


if [ -f /etc/openldap/cacerts/cert.pem ]
        then
                echo "------------------------------ Ja existe um certificado configurado -------------------------------"
                echo
        else
                cat <<\EOF > /etc/openldap/cacerts/cert.pem
-----BEGIN CERTIFICATE-----
MIIDnzCCAwigAwIBAgIJAOxbDwLbD4qdMA0GCSqGSIb3DQEBBQUAMIGSMQswCQYD
VQQGEwJCUjELMAkGA1UECBMCU1AxDjAMBgNVBAoTBVRJVklUMQ4wDAYDVQQLEwVJ
VE0tSTEoMCYGA1UEAxQfY2FfdGl2aXRfcHJveHlsZGFwLnRpdml0LmNvbS5icjEs
MCoGCSqGSIb3DQEJARYdbGlzdGFfY3NvX2VxdWlwZUB0aXZpdC5jb20uYnIwHhcN
MTMwNDI3MTY1OTU2WhcNMjgwNTA4MTY1OTU2WjCBkjELMAkGA1UEBhMCQlIxCzAJ
BgNVBAgTAlNQMQ4wDAYDVQQKEwVUSVZJVDEOMAwGA1UECxMFSVRNLUkxKDAmBgNV
BAMUH2NhX3Rpdml0X3Byb3h5bGRhcC50aXZpdC5jb20uYnIxLDAqBgkqhkiG9w0B
CQEWHWxpc3RhX2Nzb19lcXVpcGVAdGl2aXQuY29tLmJyMIGfMA0GCSqGSIb3DQEB
AQUAA4GNADCBiQKBgQDGT+Ll4qobkq2j9Qhw/M8ZgDZCvSAlDgvTnXsdEmjGpEhv
XpPbg3HJ6KJf7ev4wUWdyEt8qRJ6tay9c645ZAKvRe+w7A4Z061DM1J9qREXpnLx
Wt1sg2LdSbNmALNos71ZtFXCadGCgg7KgHjCWKV1Seevyo4f2ANmrPu+Xo7RdQID
AQABo4H6MIH3MB0GA1UdDgQWBBSF+/CT5CE1/IomAMRnyjnpwWIACjCBxwYDVR0j
BIG/MIG8gBSF+/CT5CE1/IomAMRnyjnpwWIACqGBmKSBlTCBkjELMAkGA1UEBhMC
QlIxCzAJBgNVBAgTAlNQMQ4wDAYDVQQKEwVUSVZJVDEOMAwGA1UECxMFSVRNLUkx
KDAmBgNVBAMUH2NhX3Rpdml0X3Byb3h5bGRhcC50aXZpdC5jb20uYnIxLDAqBgkq
hkiG9w0BCQEWHWxpc3RhX2Nzb19lcXVpcGVAdGl2aXQuY29tLmJyggkA7FsPAtsP
ip0wDAYDVR0TBAUwAwEB/zANBgkqhkiG9w0BAQUFAAOBgQAx3xcBaalHPf9SLwCF
mTdtLipx6JZ8tMJ/QWbNelWPwqyPDP0ux/cDDvdCJYiR58TMe2TodNly5vdFz0v5
u0c9iJSZOGyGNRAUUyYCO3o63WDaPSkJyVSaoiRiO2N0WZ+iegMPCPLqwhVyrM4g
ZqaMGJINZGKpijq7TCDA7uE0CQ==
-----END CERTIFICATE-----
EOF
chmod 600 /etc/openldap/cacerts/cert.pem

fi


grep -iE 'tvtdba|tvtmdw|tvtunix|tvtbkp' /etc/sudoers >/dev/null 2>/dev/null
if [ $? -eq 0 ]
        then
                echo "------------------------------------- Sudo ja configurado! ----------------------------------------"
                echo
        else
                cat <<\EOF >> /etc/sudoers
Cmnd_Alias      SUROOT = /bin/su -, /bin/su - root
Cmnd_Alias      PASSWDROOT = /usr/bin/passwd root
Cmnd_Alias      SHELLESCAPE = /bin/vi, /usr/bin/vim, /usr/bin/telnet, /usr/kerberos/bin/telnet, /bin/more, /usr/bin/less
Cmnd_Alias      VISUDO = /usr/sbin/visudo
Cmnd_Alias      SHELLS = /usr/bin/sh, /usr/bin/csh, /usr/bin/ksh, /usr/local/bin/tcsh, /usr/bin/rsh, /usr/bin/rsh, /usr/local/bin/zsh, /usr/bin/bash
Cmnd_Alias      SUMDW = /bin/su - jboss, /bin/su - wasusr, /bin/su - webusr, /bin/su - mqm, /bin/su - wbi, /bin/su - jbsaah, /bin/su - jbsaah2, /bin/su - infadmin, /bin/su - apache
Cmnd_Alias      SUDBA = /bin/su - oracle, /bin/su - grid
#Grupos empresa
%tvtdba1        ALL=(ALL) NOPASSWD: ALL, SUDBA, !SUROOT, !PASSWDROOT, !VISUDO
%tvtdba3        ALL=(ALL) NOPASSWD: ALL, SUDBA, !SUROOT, !PASSWDROOT, !VISUDO
%tvtmdw3        ALL=(ALL) NOPASSWD: ALL, SUMDW, !SUROOT, !PASSWDROOT, !VISUDO
%tvtmdw4        ALL=(ALL) NOPASSWD: ALL, SUMDW, !SUROOT, !PASSWDROOT, !VISUDO
%tvtunix1       ALL=(ALL) NOPASSWD: ALL, !PASSWDROOT, !VISUDO
%tvtunix3       ALL=(ALL) NOPASSWD: ALL
%tvtbkp3        ALL=(ALL) NOPASSWD: ALL
%tvtbkp         ALL=(ALL) NOPASSWD: ALL
%tvtsap         ALL=(ALL) NOPASSWD: ALL
EOF

fi


grep -iE 'ldapvip|ldapviprj' /etc/hosts >/dev/null 2>/dev/null
if [ $? -eq 0 ]
        then
                echo "-------------------------- Apontamentos no /etc/hosts configurados! -------------------------------"
                echo
        else
                cat <<\EOF >> /etc/hosts

# PROXY LDAP
200.185.94.92     ldapvip.empresa.com.br     ldapvip
200.185.102.166   ldapviprj.empresa.com.br   ldapviprj

EOF

fi



cat <<\EOF > /etc/nsswitch.conf
passwd:     files sss winbind ldap
shadow:     files sss winbind ldap
group:      files sss winbind ldap
hosts:      files dns
bootparams: nisplus [NOTFOUND=return] files
ethers:     files
netmasks:   files
networks:   files
protocols:  files
rpc:        files
services:   files
netgroup:   nisplus
publickey:  nisplus
automount:  files nisplus
aliases:    files nisplus
EOF

if [ ! -d /etc/sssd ]
        then
                mkdir -p /etc/sssd
                chmod 600 /etc/sssd
fi

if [ -f /etc/sssd/sssd.conf ]
        then
                echo "-------------------- Arquivo de configuracao /etc/sssd/sssd.conf, ja existe -----------------------"
                echo
        else
                cat <<\EOF> /etc/sssd/sssd.conf
[domain/empresa]
#debug_level = 9
id_provider = ldap
auth_provider = ldap
ldap_uri = ldaps://ldapvip.empresa.com.br:636,ldaps://ldapviprj.empresa.com.br:636
ldap_search_base = o=empresa
ldap_default_bind_dn = cn=bindempresa,ou=BINDUSERS,o=empresa
ldap_default_authtok = HwG8P4BRz576xaJ

cache_credentials = True
ldap_tls_cacertdir = /etc/openldap/cacerts
ldap_tls_reqcert = allow

[sssd]
config_file_version = 2
services = nss, pam
domains = empresa

[nss]
filter_users = ALLLOCAL
filter_groups = ALLLOCAL
EOF

chmod 600 /etc/sssd/sssd.conf

fi

        case $so_version in
        "Red Hat Enterprise Linux Server release 6"|"CentOS Linux release 6"|"CentOS release 6")
                /etc/init.d/sssd start > /dev/null 2>/dev/null
                chkconfig sssd on > /dev/null 2>/dev/null
                ;;
        "Red Hat Enterprise Linux Server release 7"|"CentOS Linux release 7")
                systemctl start sssd 2>/dev/null;systemctl enable sssd 2> /dev/null
                systemctl start oddjob 2> /dev/null; systemctl enable  oddjob 2> /dev/null
                /usr/sbin/authconfig --enablesssd --enablesssdauth --enablemkhomedir --update 2>/dev/null
                ;;
        "Red Hat Enterprise Linux Server release 8"|"CentOS Linux release 8")
                systemctl start sssd 2>/dev/null;systemctl enable sssd 2> /dev/null
                systemctl start oddjob 2> /dev/null; systemctl enable  oddjob 2> /dev/null
                authselect select sssd with-mkhomedir --force
                ;;

        esac

if [ ! -d /opt/empresa ]
        then
               mkdir -p /opt/empresa ; chmod 776 /opt/empresa
fi


}

#Remove case sensitive no bash
shopt -s nocasematch

case $1 in
            zabbix) install_zabbix 2>/dev/null       ;;
              salt) install_salt 2>/dev/null         ;;
              ldap) install_sssd 2>/dev/null         ;;
            banner) banner_conf 2>/dev/null          ;;
        empresa_repo) install_repo_empresa 2 > /dev/null ;;
             *) echo "|=================================================| Help |========================================================|"
                echo "|                                                                                                                 |"
                echo "| Modo de uso:                                                                                                    |"
                echo "|                                                                                                                 |"
                echo "|=================================================================================================================|"
                echo "|                                                                                                                 |"
                echo "| * Execute o script com os parametros abaixo conforme desejado:                                                  |"
                echo "|                                                                                                                 |"
                echo "|                                                                                                                 |"
                echo "| banner     = para configurar banner e ps1        # ao informar cliente, sera configurado ps1 com nome           |"
                echo "| empresa_repo = para configurar repositorio empresa   # Centos/rhel 6,7 e 8                                          |"
                echo "| zabbix     = para instalacao do zabbix           # Centos/rhel 6,7 e 8        | Necessario ip do master/proxy   |"
                echo "| salt       = para instalacao do salt             # Centos/rhel 6,7/Suse 11,12 | Necessario ip do syndic e CID   |"
                echo "| ldap       = para instalacao do ldap (sssd)      # Centos/rhel 6,7 e 8                                          |"
                echo "|                                                                                                                 |"
                echo "| Exemplo:                                                                                                        |"
                echo "|                                                                                                                 |"
                echo "| ./aceite_empresa_linux zabbix                                                                                     |"
                echo "|                                                                                                                 |"
                echo "|=================================================================================================================|"
esac

