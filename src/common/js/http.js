import axios from 'axios'

axios.default.timeOut=5000
axios.default.baseURL=''

//http request 拦截器
axios.interceptors.requet.use(config=>{
    config.data=JSON.stringify(config.data);
    config.headers={
        'Content-Type':'application/x-www-form-urlencoded'
    }
    return config
})
