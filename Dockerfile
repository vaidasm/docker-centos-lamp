FROM centos:7
MAINTAINER "DataDog" <info@datadog.lt>

ENV USER_GUID 1000
ENV USER_UID 1000

# Run updates
RUN yum -y update; yum clean all;

# Install supervisor
RUN yum -y install python-setuptools;
RUN easy_install supervisor
RUN /usr/bin/echo_supervisord_conf > /etc/supervisord.conf
RUN mkdir -p /var/log/supervisor
RUN sed -i -e "s/^nodaemon=false/nodaemon=true/" /etc/supervisord.conf
RUN mkdir /etc/supervisord.d
RUN echo [include] >> /etc/supervisord.conf
RUN echo 'files = /etc/supervisord.d/*.ini' >> /etc/supervisord.conf

# Install and setup sshd
RUN yum install -y openssh-server openssh-clients passwd
RUN ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key && ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key
RUN sed -ri 's/UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config && echo 'root:changeme' | chpasswd

# Install nginx
COPY nginx/nginx.repo /etc/yum.repos.d/nginx.repo
RUN yum -y install nginx --enablerepo=nginx;
RUN mkdir /etc/nginx/sites-available
RUN mkdir /etc/nginx/sites-enabled

# Install MySQL
RUN yum -y install http://repo.mysql.com/mysql-community-release-el7-5.noarch.rpm;
RUN yum -y install mysql-community-server;

# Install PHP
RUN yum -y install http://rpms.famillecollet.com/enterprise/remi-release-7.rpm
RUN yum -y install --enablerepo=remi,remi-php56 php-fpm php-mcrypt php-mysqlnd php-mbstring

# Install composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer

# Add www user
RUN groupadd www -g ${USER_GUID}
RUN useradd www -g ${USER_GUID} -u ${USER_UID}
RUN echo 'www:changeme' | chpasswd

# Enable sudo with no passwd
RUN yum install -y sudo
RUN groupadd sudo
RUN echo "%sudo ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
RUN gpasswd -a www sudo

# Copy configs
COPY php/www.conf /etc/php-fpm.d/www.conf
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/default.conf /etc/nginx/sites-available/default.conf
RUN ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf

COPY supervisor/*.ini /etc/supervisord.d/

COPY mysql/mysql_start.sh /usr/local/bin/mysql_start.sh
RUN chmod +x /usr/local/bin/mysql_start.sh
COPY mysql/my.cnf /etc/my.cnf

RUN chown -R www:www /etc/nginx /var/lib/mysql /var/www /var/lib/php/session

VOLUME /var/www /var/log/shared /var/lib/mysql
EXPOSE 22 80 3306

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
