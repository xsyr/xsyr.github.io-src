---
layout: post
title: "color logger"
date: 2014-01-07 20:01
comments: true
categories: C/C++
---


写了个简单的 logger，方便调试。

```cpp

#ifndef OAM_PTP_LOGGER_H_
#define OAM_PTP_LOGGER_H_

namespace log
{

enum LogLevel {
  kDebug,
  kInfo,
  kWarn,
  kError,
  kFatal
};

class Logger {
 public:
  Logger() { }
  virtual void Write(LogLevel level, const char* format, ...) = 0;
  virtual ~Logger() { }

 private:
  Logger(const Logger& logger);
  void operator=(const Logger& logger);
};

/**
 * @brief Do nothing.
 */
class DummyLogger : public Logger {
 public:
  virtual void Write(LogLevel level, const char* format, ...) {
    (void)level;
    (void)format;
  }

};

}

#endif /* end of include guard: OAM_PTP_LOGGER_H_ */

```

<!-- more -->

```cpp

namespace log
{

class ColorLogger : public ptp::log::Logger {
 public:
  virtual void Write(ptp::log::LogLevel level, const char* format, ...) {

    time_t now = time(NULL);
    struct tm *ptm = localtime(&now);
    char buf[64] = {0};
    snprintf(buf, sizeof(buf), "[%02d-%02d-%02d %02d:%02d:%02d]",
             (ptm->tm_year + 1900) / 100,
             ptm->tm_mon + 1,
             ptm->tm_mday,
             ptm->tm_hour,
             ptm->tm_min,
             ptm->tm_sec);

    switch(level) {
      case ptp::log::kDebug: this->Debug(buf, format); break;
      case ptp::log::kInfo:  this->Info(buf, format);  break;
      case ptp::log::kWarn:  this->Warn(buf, format);  break;
      case ptp::log::kError: this->Error(buf, format); break;
      case ptp::log::kFatal: this->Fatal(buf, format); break;
    };


    va_list args;
    va_start(args, format);
    vprintf(this->buffer_, args);
    va_end(args);

  }

 private:

  void Debug(const char *time, const char *format) {
    sprintf(this->buffer_,
            "\033[1;37m[Debug] %s \033[00;00m\033[0;37m%s\033[0m\n",
            time,
            format);
  }
  void Info(const char *time, const char *format) {
    sprintf(this->buffer_,
            "\033[1;32m[Info ] %s \033[00;00m\033[0;32m%s\033[0m\n",
            time,
            format);
  }
  void Warn(const char *time, const char *format) {
    sprintf(this->buffer_,
            "\033[1;33m[Warn ] %s \033[00;00m\033[0;33m%s\033[0m\n",
           time,
           format);
  }
  void Error(const char *time, const char *format) {
    sprintf(this->buffer_,
            "\033[1;31m[Error] %s \033[00;00m\033[0;31m%s\033[0m\n",
            time,
            format);
  }
  void Fatal(const char *time, const char *format) {
    sprintf(this->buffer_,
            "\033[1;31m[Fatal] %s \033[00;00m\033[0;31m%s\033[00;00m\n",
            time,
            format);
  }

  char buffer_[1024];
};

} /// namespace log
```
