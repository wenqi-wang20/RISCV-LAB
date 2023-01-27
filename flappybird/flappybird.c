int main()
{
    // 整个游戏分为三个阶段
    // 1. 游戏开始阶段，跳动的鸟和显示 flappy bird 的字体，检测 push button 按钮开始游戏
    // 2. 游戏主循环，通过 push button 按钮开始包含经过柱子的检测，为游戏计分
    // 3. 游戏结束的判断，卡在结束页面不再循环

    /*
    ***Note: 为了节省寄存器，并且无法使用宏定义，所以游戏相关的常数都会定义在注释里
    0. 两块 block ram 缓冲区的初始写入地址
        char *bram_0 = (char *)0x81000000;
        char *bram_1 = (char *)0x84000000;
    1. 蓝色背景 0x57
    2. 开始标题 FlappyBird
        size :  140*40=5600     from 0
        flash:  0x8330_0000 -> 0x8330_15e0
        coord:  (30, 10) -> (170, 50)   10*200+30=2030  50*200+170=10170
        *bram:  0x**00_07ee -> 0x**00_27ba
    3. 地面
        size :  200*25=5000     from 5600
        flash:  0x8330_15e0 -> 0x8330_2968
        coord:  (0, 125) -> (200, 150)  125*200+0=25000  150*200+200=30200
        *bram:  0x**00_61a8 -> 0x**00_7530
    4. 小鸟(平飞)
        size :  36*25=900       from 10600
        flash:  0x8330_2968 -> 0x8330_2cec
        coord:  (82, 55) -> (118, 80)  55*200+82=11082  80*200+118=16118
        *bram:  0x**00_2b4a -> 0x**00_3ef6
    5. 小鸟(下降)
        size :  36*25=900       from 11500
        flash:  0x8330_2cec -> 0x8330_3070
        coord:  (82, 58) -> (118, 83)  58*200+82=11682  83*200+118=16718
        *bram:  0x**00_2da2 -> 0x**00_40ea
    6. 小鸟(上升)
        size :  36*25=900       from 12400
        flash:  0x8330_3070 -> 0x8330_33f4
        coord:  (82, 52) -> (118, 77)  52*200+82=10482  77*200+118=15518
        *bram:  0x**00_28f2 -> 0x**00_3c9e
    7. 小鸟撞击地面位置     100*200+82=20082 = 0x4e72
    8. 小鸟撞到上表面位置   3*200+82=82 = 0x2aa

    上下柱子之间的间隙为 55
    上下柱子的长度之和为 70 (0-10-20-30-40-50-60-70)
    for example:
        上柱子长度为 40
        上柱子的坐标为 (150, 0) -> (200, 40)  0*200+150=150=0x96
        flash 存储为 47cc+(100-40)*50=21300=0x5334
        下柱子长度为 30
        下柱子的坐标为 (150, 95) -> (200, 125) 95*200+150=19150=0x4ace
        flash 存储为 33f4

    9. 柱子(下底面)
        size :  50*100=5000     from 13300
        flash:  0x8330_33f4 -> 0x8330_477c
        coord:  changeble
        *bram:  changeble
    10. 柱子(上底面)
        size :  50*100=5000     from 18300
        flash:  0x8330_477c -> 0x8330_5b04
        coord:  changeble
        *bram:  changeble
    11. 结束标题
        size :  150*40=6000     from 23300
        flash:  0x8330_5b04 -> 0x8330_7274
        coord:  (25, 60) -> (175, 100)   60*200+25=12025  100*200+175=20175
        *bram:  0x**00_2ef9 -> 0x**00_4ecf
    */

    /*
     ********************** 准备区 **********************
     */

    // flappy bird 相关的游戏素材都从 0x300000 地址开始存储
    int *buttons = (int *)0x85000004;
    char *flash = (char *)0x83300000;

    // 渲染时的 bram 写入指针
    char *bram_tmp;

    // 定义当前渲染 vga 读取的 Block ram 片区
    // 0 -> bram_0  1 -> bram_1
    int sele = 0;
    int *bram_sele = (int *)0x86000004;

    // 先全部渲染为蓝色
    bram_tmp = (char *)0x84000000;
    while (bram_tmp < (char *)0x84000000 + 120000)
        *(bram_tmp++) = 0x57;

    *bram_sele = 1;

    // 定义当前渲染的分辨率为 200*150
    int *vga_scale = (int *)0x86000000;
    *vga_scale = 2;

    // 定义渲染部分图片时所需要的相对行列位置
    int row = 0;
    int col = 0;

    // 定义延时计数器
    int frame = 0;

    // 先将第一部分游戏画面写好
    bram_tmp = (char *)0x81000000;
    // 1. 渲染蓝色背景
    int i = 0;
    while (i != 30000)
    {
        *(bram_tmp + i) = 0x57;
        i = i + 1;
    }
    i = 0;
    // 2. 渲染开始标板
    flash = (char *)0x83300000;
    bram_tmp = (char *)0x810007ee;
    while (i != 5600)
    {
        *(bram_tmp + row * 200 + col) = *(flash + i);
        i = i + 1;
        col = col + 1;

        if (col == 140)
        {
            row = row + 1;
            col = 0;
        }
    }
    i = 0;
    row = 0;
    col = 0;
    // 3. 渲染地面
    flash = (char *)0x833015e0;
    bram_tmp = (char *)0x810061a8;
    while (i != 5000)
    {
        *(bram_tmp + row * 200 + col) = *(flash + i);
        i = i + 1;
        col = col + 1;

        if (col == 200)
        {
            row = row + 1;
            col = 0;
        }
    }
    i = 0;
    row = 0;
    col = 0;
    // 4. 渲染小鸟(平飞)
    flash = (char *)0x83302968;
    bram_tmp = (char *)0x81002b4a;
    while (i != 900)
    {
        *(bram_tmp + row * 200 + col) = *(flash + i);
        i = i + 1;
        col = col + 1;

        if (col == 36)
        {
            row = row + 1;
            col = 0;
        }
    }
    i = 0;
    row = 0;
    col = 0;

    /*
     ********************** 进入开始画面 **********************
     */

    // 定义 pushbutton 现在状态，形成类似于上升下降沿
    int now_button = 0;
    // 定义按键次数
    int button_count = 0;
    // 定义辅助计数帧
    int pilot_count = 0;
    // 定义渲染帧数
    int cnt = 0;
    // 定义按键状态
    int push = 0;

    // 定义双缓冲区每次清除画布起始位置的缓冲变量
    int bird_position_0 = 0;
    int bird_position_1 = 0;
    int up_pipe_position_0 = 0;
    int up_pipe_position_1 = 0;
    int down_pipe_position_0 = 0;
    int down_pipe_position_1 = 0;

    // 记录小鸟高度的变量
    int bird_height = 0;

    // 检测第一次 push, 渲染开始画面的第一帧，计算下一帧(小鸟下飞)
    while (1)
    {
        // 取出现在的状态
        push = (*buttons) & 0x00000001;

        // 如果状态不同需要修改，同时判定是否是上边沿
        if (push == 1 && now_button == 0)
        {
            now_button = 1;
            cnt = cnt + 1;
            *bram_sele = 0;
            *vga_scale = 2;
            bram_tmp = (char *)0x84000000;

            // 开始写游戏开始画面的缓冲区
            // 1. 渲染蓝色背景
            i = 0;
            while (i != 30000)
            {
                *(bram_tmp + i) = 0x57;
                i = i + 1;
            }
            i = 0;
            // 2. 渲染开始标板
            flash = (char *)0x83300000;
            bram_tmp = (char *)0x840007ee;
            while (i != 5600)
            {
                *(bram_tmp + row * 200 + col) = *(flash + i);
                i = i + 1;
                col = col + 1;

                if (col == 140)
                {
                    row = row + 1;
                    col = 0;
                }
            }
            i = 0;
            row = 0;
            col = 0;
            // 3. 渲染地面
            flash = (char *)0x833015e0;
            bram_tmp = (char *)0x840061a8;
            while (i != 5000)
            {
                *(bram_tmp + row * 200 + col) = *(flash + i);
                i = i + 1;
                col = col + 1;

                if (col == 200)
                {
                    row = row + 1;
                    col = 0;
                }
            }
            i = 0;
            row = 0;
            col = 0;
            // 4. 渲染小鸟(下飞)
            flash = (char *)0x83302cec;
            bram_tmp = (char *)0x84002da2;
            while (i != 900)
            {
                *(bram_tmp + row * 200 + col) = *(flash + i);
                i = i + 1;
                col = col + 1;

                if (col == 36)
                {
                    row = row + 1;
                    col = 0;
                }
            }
            i = 0;
            row = 0;
            col = 0;

            // 跳出开始游戏的循环
            break;
        }
        else if (push == 0 && now_button == 1)
        {
            now_button = 0;
        }
    }

    // 进入开始页面循环, 检测第二次 push 退出开始页面，进入游戏主循环
    now_button = 0;
    cnt = 0;

    // 循环帧数延时
    frame = 0;
    while (frame != 50000)
    {
        frame = frame + 1;
    }
    cnt = cnt + 1;
    sele = 1 - cnt % 2;
    // 给出交换信号之后，可能要等到同步信号真正来临之后才会交换，所以要等待一段时间
    *bram_sele = sele;
    while (1)
    {

        // 清除中央小鸟画布
        // (82, 50) -> (118, 85)
        bram_tmp = sele == 1 ? (char *)0x81002762 : (char *)0x84002762;
        i = 0;
        while (i != 1260)
        {
            *(bram_tmp + row * 200 + col) = 0x57;
            i = i + 1;
            col = col + 1;

            if (col == 36)
            {
                row = row + 1;
                col = 0;
            }
        }
        i = 0;
        row = 0;
        col = 0;

        // 如果 button_count = 1, 则开始从下往上去除标题面板
        if (button_count == 1)
        {

            if (pilot_count > 3)
            {
                bram_tmp = sele == 1 ? (char *)0x810007ee : (char *)0x840007ee;
            }
            else if (pilot_count % 4 == 0)
            {
                bram_tmp = sele == 1 ? (char *)0x81001f5e : (char *)0x84001f5e;
            }
            else if (pilot_count % 4 == 1)
            {
                bram_tmp = sele == 1 ? (char *)0x8100178e : (char *)0x8400178e;
            }
            else if (pilot_count % 4 == 2)
            {
                bram_tmp = sele == 1 ? (char *)0x81000fbe : (char *)0x84000fbe;
            }
            else
            {
                bram_tmp = sele == 1 ? (char *)0x810007ee : (char *)0x840007ee;
            }
            while (i != 1400 * (pilot_count % 4 + 1))
            {
                *(bram_tmp + row * 200 + col) = 0x57;
                i = i + 1;
                col = col + 1;

                if (col == 140)
                {
                    row = row + 1;
                    col = 0;
                }
            }
            i = 0;
            row = 0;
            col = 0;
            pilot_count = pilot_count + 1;
        }

        // 开始下一帧小鸟的渲染
        if (cnt % 4 == 1 || cnt % 4 == 3)
        {
            // 平飞
            flash = (char *)0x83302968;
            bram_tmp = sele == 1 ? (char *)0x81002b4a : (char *)0x84002b4a;
            bird_height = 55;
            // 更新此缓冲区上鸟的位置
            if (sele == 1)
            {
                bird_position_0 = 0x2b4a;
            }
            else
            {
                bird_position_1 = 0x2b4a;
            }
        }
        else if (cnt % 4 == 2)
        {
            // 上飞
            flash = (char *)0x83303070;
            bram_tmp = sele == 1 ? (char *)0x810028f2 : (char *)0x840028f2;
            bird_height = 52;
            // 更新此缓冲区上鸟的位置
            if (sele == 1)
            {
                bird_position_0 = 0x28f2;
            }
            else
            {
                bird_position_1 = 0x28f2;
            }
        }
        else
        {
            // 下飞
            flash = (char *)0x83302cec;
            bram_tmp = sele == 1 ? (char *)0x81002da2 : (char *)0x84002da2;
            bird_height = 58;
            // 更新此缓冲区上鸟的位置
            if (sele == 1)
            {
                bird_position_0 = 0x2da2;
            }
            else
            {
                bird_position_1 = 0x2da2;
            }
        }

        while (i != 900)
        {
            *(bram_tmp + row * 200 + col) = *(flash + i);
            i = i + 1;
            col = col + 1;

            if (col == 36)
            {
                row = row + 1;
                col = 0;
            }
        }
        i = 0;
        row = 0;
        col = 0;

        // 在交换渲染页前后各加一点延时
        // 循环帧数延时
        cnt = cnt + 1;
        sele = 1 - cnt % 2;
        *bram_sele = sele;

        frame = 0;
        while (frame != 40000)
        {
            frame = frame + 1;
        }

        // 检测按键状态
        push = (*buttons) & 0x00000001;
        if (push == 1 && now_button == 0)
        {
            button_count = button_count + 1;
            now_button = 1;
        }
        else if (push == 0 && now_button == 1)
        {
            now_button = 0;
        }

        // 按键次数为 2 时，跳出开始页面循环，进入游戏主循环
        if (button_count == 2)
        {
            break;
        }
    }

    /*
     ********************** 进入游戏主循环 **********************
     */

    i = 0;
    row = 0;
    col = 0;
    cnt = 0;
    now_button = 0;
    button_count = 0;

    // 假设 up pipe 的位置都为 (150,1) = 0x15e, down pipe 的位置都为 (150, 95) = 0x4ace
    // 假设 up pipe 的位置都为 (175,1) = 0x177, down pipe 的位置都为 (175, 95) = 0x4ae7
    // 假设 up pipe 的位置都为 (200,1) = 0x190, down pipe 的位置都为 (200, 95) = 0x4b00
    up_pipe_position_0 = 0x190;
    up_pipe_position_1 = 0x190;
    down_pipe_position_0 = 0x4b00;
    down_pipe_position_1 = 0x4b00;

    int pipe0 = 39;
    int pipe1 = 19;
    int pipe2 = 59;
    int pipe3 = 29;
    int pipe4 = 49;

    // 记录当前画面中上柱子的高度，下柱子高度为 69-上柱子高度
    int up_pipe_height = 39;
    // 设置柱子之间交替的转换帧
    int pipe_change_frame = 0;
    // 设置柱子的横坐标
    int pipe_x = 200;

    // 设置 pipe 进入和离开 1 进入 0 正常 -1 离开
    int pipe_status = 1;

    // 此时当前页面上渲染的 bram 是 sele，下一帧是 1 - sele

    // 定义小鸟目前缓冲存在的 jump bank，初始为 0
    // 每按下一次按键，jump bank = 1
    int jump_bank = 0;
    // 判断游戏退出的变量
    int lose_flag = 0;

    while (1)
    {
        // 检测 push button
        push = (*buttons) & 0x00000001;
        if (push == 1 && now_button == 0)
        {
            jump_bank = 1;
            button_count = button_count + 1;
            now_button = 1;
        }
        else if (push == 0 && now_button == 1)
        {
            now_button = 0;
        }

        // 渲染画面
        // 1. 渲染小鸟

        // 先从记录的位置清除缓存区上次的小鸟
        bram_tmp = sele == 1 ? (char *)0x81000000 : (char *)0x84000000;
        bram_tmp = bram_tmp + (sele == 1 ? bird_position_0 : bird_position_1);
        while (i != 900)
        {
            *(bram_tmp + row * 200 + col) = 0x57;
            i = i + 1;
            col = col + 1;

            if (col == 36)
            {
                row = row + 1;
                col = 0;
            }
        }
        i = 0;
        row = 0;
        col = 0;

        // 根据跳跃条件判断小鸟位置
        if (jump_bank > 0)
        {
            // 如果有跳跃，减少跳跃 bank
            jump_bank = jump_bank - 1;

            // 更新小鸟的位置，比上一帧上升 18 个像素
            bram_tmp = sele == 1 ? (char *)0x81000000 : (char *)0x84000000;
            bram_tmp = bram_tmp + (sele == 1 ? bird_position_1 : bird_position_0) - 18 * 200;
            bird_height = bird_height - 18;

            // 同时更改此缓冲区小鸟的位置
            if (sele == 1)
            {
                bird_position_0 = bird_position_1 - 18 * 200;
            }
            else
            {
                bird_position_1 = bird_position_0 - 18 * 200;
            }
        }
        else
        {
            // 如果没有跳跃，那么就会下坠

            // 更新小鸟的位置，比上一帧下降 6 个像素
            bram_tmp = sele == 1 ? (char *)0x81000000 : (char *)0x84000000;
            bram_tmp = bram_tmp + (sele == 1 ? bird_position_1 : bird_position_0) + 3 * 200;
            bird_height = bird_height + 3;

            // 同时更改此渲染缓冲区小鸟的高度
            if (sele == 1)
            {
                bird_position_0 = bird_position_1 + 3 * 200;
            }
            else
            {
                bird_position_1 = bird_position_0 + 3 * 200;
            }
        }

        // 从 flash 中 加载资源
        if (cnt % 4 == 1 || cnt % 4 == 3)
        {
            // 平飞
            flash = (char *)0x83302968;
        }
        else if (cnt % 4 == 2)
        {
            // 上飞
            flash = (char *)0x83303070;
        }
        else
        {
            // 下飞
            flash = (char *)0x83302cec;
        }

        // 超出边界的小鸟，按照边界情况来渲染
        if (sele == 1 && (bird_position_0 > 0x4e72))
        {
            bird_position_0 = 0x4e72;
            bram_tmp = (char *)0x81000000 + bird_position_0;
            lose_flag = 1;
        }
        else if (sele == 1 && (bird_position_0 < 0x2aa))
        {
            bird_position_0 = 0x2aa;
            bram_tmp = (char *)0x81000000 + bird_position_0;
            lose_flag = 1;
        }
        else if (sele == 0 && (bird_position_1 > 0x4e72))
        {
            bird_position_1 = 0x4e72;
            bram_tmp = (char *)0x84000000 + bird_position_1;
            lose_flag = 1;
        }
        else if (sele == 0 && (bird_position_0 < 0x2aa))
        {
            bird_position_1 = 0x2aa;
            bram_tmp = (char *)0x84000000 + bird_position_1;
            lose_flag = 1;
        }

        while (i != 900)
        {
            *(bram_tmp + row * 200 + col) = *(flash + i);
            i = i + 1;
            col = col + 1;

            if (col == 36)
            {
                row = row + 1;
                col = 0;
            }
        }
        i = 0;
        row = 0;
        col = 0;

        // 2. 渲染管道

        // 先从记录的位置清除缓存区上次的管道
        bram_tmp = sele == 1 ? (char *)0x81000000 : (char *)0x84000000;
        bram_tmp = bram_tmp + (sele == 1 ? up_pipe_position_0 : up_pipe_position_1);
        while (i != 50 * up_pipe_height)
        {
            *(bram_tmp + row * 200 + col) = 0x57;
            i = i + 1;
            col = col + 1;

            if (col == 50)
            {
                row = row + 1;
                col = 0;
            }
        }
        i = 0;
        row = 0;
        col = 0;

        bram_tmp = sele == 1 ? (char *)0x81000000 : (char *)0x84000000;
        bram_tmp = bram_tmp + (sele == 1 ? down_pipe_position_0 : down_pipe_position_1);
        while (i != 50 * (69 - up_pipe_height) + 50)
        {
            *(bram_tmp + row * 200 + col) = 0x57;
            i = i + 1;
            col = col + 1;

            if (col == 50)
            {
                row = row + 1;
                col = 0;
            }
        }
        i = 0;
        row = 0;
        col = 0;

        // 判断 pipe 下一帧的位置
        // 如果当前不是管道切换的转换帧，那么位置就会向左移动 5 个像素
        if (pipe_change_frame == 0)
        {
            bram_tmp = sele == 1 ? (char *)0x81000000 : (char *)0x84000000;
            bram_tmp = bram_tmp + (sele == 1 ? up_pipe_position_1 : up_pipe_position_0) - 5;
            if (sele == 1)
            {
                up_pipe_position_0 = up_pipe_position_1 - 5;
            }
            else
            {
                up_pipe_position_1 = up_pipe_position_0 - 5;
            }
            pipe_x = pipe_x - 5;

            // 当 pipe 移动到最左边时，生成一个切换帧
            if ((sele == 1 && up_pipe_position_0 <= 160) || (sele == 0 && up_pipe_position_1 <= 160))
            {
                pipe_change_frame = 2;
            }
        }
        // 如果是切换帧，则将 pipe 的位置移到最右边
        else
        {
            bram_tmp = sele == 1 ? (char *)0x81000000 : (char *)0x84000000;
            bram_tmp = bram_tmp + 200 + 200 - 5;
            if (sele == 1)
            {
                up_pipe_position_0 = 200 + 200 - 5;
            }
            else
            {
                up_pipe_position_1 = 200 + 200 - 5;
            }
            pipe_x = 200 - 5;

            pipe_change_frame -= 1;
        }
        // 从 flash 中 加载 up pipe 资源
        flash = (char *)0x8330477c + (100 - up_pipe_height) * 50;
        while (i != 50 * up_pipe_height)
        {
            *(bram_tmp + row * 200 + col) = *(flash + i);
            i = i + 1;
            col = col + 1;

            if (col == 50)
            {
                row = row + 1;
                col = 0;
            }
        }
        i = 0;
        row = 0;
        col = 0;

        // 判断 pipe 当前的状态
        int position = sele == 1 ? up_pipe_position_0 : up_pipe_position_1;
        if (position <= 200)
        {
            // 离开
            pipe_status = -1;
        }
        else if (position <= 200 + 200 && position >= 200 + 145)
        {
            // 进入
            pipe_status = 1;
        }
        else
        {
            // 运行
            pipe_status = 0;
        }

        // 如果当前不是管道切换的转换帧，那么位置就会向左移动 5 个像素
        if (pipe_change_frame == 0 || pipe_change_frame == 2)
        {
            bram_tmp = sele == 1 ? (char *)0x81000000 : (char *)0x84000000;
            bram_tmp = bram_tmp + (sele == 1 ? down_pipe_position_1 : down_pipe_position_0) - 5;
            if (sele == 1)
            {
                down_pipe_position_0 = down_pipe_position_1 - 5;
            }
            else
            {
                down_pipe_position_1 = down_pipe_position_0 - 5;
            }
        }
        // 如果是切换帧，则将 pipe 的位置移到最右边
        else
        {
            bram_tmp = sele == 1 ? (char *)0x81000000 : (char *)0x84000000;
            bram_tmp = bram_tmp + 0x4b00 - 5;
            if (sele == 1)
            {
                down_pipe_position_0 = 0x4b00 - 5;
            }
            else
            {
                down_pipe_position_1 = 0x4b00 - 5;
            }

            pipe_change_frame -= 1;
        }
        // 从 flash 中 加载 down pipe 资源
        flash = (char *)0x833033f4;
        while (i != 50 * (69 - up_pipe_height))
        {
            *(bram_tmp + row * 200 + col) = *(flash + i);
            i = i + 1;
            col = col + 1;

            if (col == 50)
            {
                row = row + 1;
                col = 0;
            }
        }
        i = 0;
        row = 0;
        col = 0;

        // 进入状态需要把画面左边的柱子遮挡掉
        // 宽度为 50
        if (pipe_status == 1)
        {
            bram_tmp = sele == 1 ? (char *)0x81000000 : (char *)0x84000000;
            while (i != 50 * 125)
            {
                *(bram_tmp + row * 200 + col) = 0x57;
                i = i + 1;
                col = col + 1;

                if (col == 50)
                {
                    row = row + 1;
                    col = 0;
                }
            }
            i = 0;
            row = 0;
            col = 0;
        }
        // 离开状态需要把画面右边的柱子遮挡掉
        else if (pipe_status == -1)
        {
            bram_tmp = sele == 1 ? (char *)0x81000000 : (char *)0x84000000;
            bram_tmp = bram_tmp + 150;
            while (i != 50 * 125)
            {
                *(bram_tmp + row * 200 + col) = 0x57;
                i = i + 1;
                col = col + 1;

                if (col == 50)
                {
                    row = row + 1;
                    col = 0;
                }
            }
            i = 0;
            row = 0;
            col = 0;
        }

        // 撞到管道判负
        if ((pipe_x <= 110 && pipe_x >= 40) && (bird_height <= up_pipe_height || bird_height + 25 >= 125 - (69 - up_pipe_height)))
        {
            lose_flag = 1;
        }

        // 游戏结束标题
        if (lose_flag > 0)
        {
            bram_tmp = sele == 1 ? (char *)0x81000000 : (char *)0x84000000;
            bram_tmp = bram_tmp + 200 * 60 + 25;
            flash = (char *)0x83305b04;
            while (i != 6000)
            {
                *(bram_tmp + row * 200 + col) = *(flash + i);
                i = i + 1;
                col = col + 1;

                if (col == 150)
                {
                    row = row + 1;
                    col = 0;
                }
            }
            i = 0;
            row = 0;
            col = 0;
        }

        // 交换缓冲区
        cnt = cnt + 1;
        if (cnt == 5)
        {
            cnt = 0;
        }
        sele = 1 - sele;
        *bram_sele = sele;

        frame = 0;
        while (frame != 5000)
        {
            frame = frame + 1;
        }

        // 结算阶段
        if (lose_flag > 0)
        {
            break;
        }
    }
}