
An experiment to make fpga as Virtio NIC with virtio_net driver

As title, this one is a virtio nic implementation works with
- virtio_net driver in linux
- virtio driver in dpdk

Also, MMIO is not tested, only MSI-X interrput is supported
The testing is done on PCIe 2.0 on Intel Celeron N3350 (on a zimaBoard)

The reference FPGA board is purchased from taobao

