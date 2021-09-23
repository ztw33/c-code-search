# CCSIO: a C-Code-Search tool
朱庭纬 2021-9-21
## 环境配置
### 安装klee
下载修改过的klee源码，参考KLEE[官方安装文档](https://klee.github.io/build-llvm9/)进行配置，具体而言有以下步骤：
- 安装依赖
```shell
$ sudo apt-get install build-essential curl libcap-dev git cmake libncurses5-dev python-minimal python-pip unzip libtcmalloc-minimal4 libgoogle-perftools-dev libsqlite3-dev doxygen
```
For Ubuntu >= 18.04, some additional packages may be required along with the ones mentioned above:
```shell
$ sudo apt-get install python3 python3-pip gcc-multilib g++-multilib 
```

- 安装llvm
> 注意：官方文档建议llvm9，此工具的开发环境为llvm6，因此此处安装llvm6.
```shell
$ sudo apt-get install clang-6.0 llvm-6.0 llvm-6.0-dev llvm-6.0-tools
```

- 安装约束求解器

此处选择STP. 按照此[链接](https://klee.github.io/build-stp/)安装即可。

- 构建uClibc和POSIX环境
```shell
$ git clone https://github.com/klee/klee-uclibc.git  
$ cd klee-uclibc  
$ ./configure --make-llvm-lib  
$ make -j2  
$ cd .. 
```
- 安装klee

建立一些链接：
```shell
$ sudo ln -s /usr/bin/llvm-config-6.0 /usr/bin/llvm-config
$ sudo ln -s /usr/bin/clang-6.0 /usr/bin/clang
```

在klee目录下：
```shell
$ mkdir build
$ cd build
$ cmake \
    -DENABLE_SOLVER_STP=ON \
    -DENABLE_UNIT_TESTS=OFF \
    -DENABLE_SYSTEM_TESTS=OFF \
    -DENABLE_POSIX_RUNTIME=ON \
    -DENABLE_KLEE_UCLIBC=ON \
    -DKLEE_UCLIBC_PATH=../../klee-uclibc \  # -DKLEE_UCLIBC_PATH为klee-uclibc根目录
    ..  
$ make
```

> NOTICE: 如果出现 `Could NOT find ZLIB (missing: ZLIB_LIBRARY ZLIB_INCLUDE_DIR)` 错误，执行`sudo apt-get install zlib1g-dev`.

### 安装mysql
```shell
$ sudo apt-get install mysql-server libmysqlclient-dev
$ sudo mysql_secure_installation  # 进行相应配置
$ pip install mysql-connector
```
#### 创建数据库&表
```
> create database CodeQuery;
> use CodeQuery;
> create table `func_signature` (
    `id` INT UNSIGNED primary key AUTO_INCREMENT,
    `func_name` VARCHAR(64) NOT NULL,
    `file_path` VARCHAR(128) NOT NULL,
    `ret_type` VARCHAR(32),
    `param_num` INT,
    `param_type` VARCHAR(64),
    `doc` TEXT,
    `keyword` TINYTEXT
    )ENGINE=InnoDB DEFAULT CHARSET=utf8;
> create table `pc` (
    `func_id` INT UNSIGNED NOT NULL,
    `smt_filepath` VARCHAR(128) NOT NULL
    )ENGINE=InnoDB DEFAULT CHARSET=utf8;
```

## 离线编码
在`OfflineEncode`文件夹下新建`inter_files`文件夹及以下子文件夹：
```
CodeSearch
    |------OfflineEncode
    |   |------inter_files
    |   |   |------0_src_code
    |   |   |------1_DriverCode
    |   |   |------2_BCFile
    |   |   |------3_SMT           
    |   |
    |   |------...
    |       
    |------...
```
将需要入库的c代码文件放置在`OfflineEncode/inter_files/0_src_code/`下，**注意，文件名需要和函数名相同**，如：
```c
get_sign.c:
    int get_sign(int x) {
        if (x == 0)
            return 0;
        if (x < 0)
            return -1;
        else
            return 1;
    }
```
在`OfflineEncode`文件夹下，执行`sh encode.sh inter_files/0_src_code/{func_name}.c`即可。如`sh encode.sh inter_files/0_src_code/get_sign.c`.

## 在线查询
安装z3求解器：`pip install z3-solver`

进入`OnlineSearch`目录下，创建`query.json`文件作为查询条件，`query.json`文件内容如下：
```json
{
    "param_num": 1,
    "param_type": ["int"],
    "param_val": [-3],
    "ret_type": "int",
    "ret_val": -1
}
```
分别为参数数目、参数类型、参数值、返回值类型、返回值，以上示例代表一组I/O示例查询：
```
INPUT
    p1: type = int, val = -3
OUTPUT
    ret: type = int, val = -1
```
执行`python search.py query.json`，若库中有满足I/O示例查询条件的，则会输出函数id。

> 本工具只支持C语言函数参数为int, char等基本类型的以及char型数组的、返回值为基本类型和char*的；只支持对参数无副作用且一定有返回值的函数进行处理。

