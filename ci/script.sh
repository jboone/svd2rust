set -ex

test_gen() {
    target/$TARGET/release/svd2rust -i $td/$svd $1 > $td/src/lib.rs
    echo 'extern crate volatile_register;' >> $td/src/lib.rs
    cargo build --manifest-path $td/Cargo.toml
}

main() {
    cross build --target $TARGET
    cross build --target $TARGET --release

    if [ ! -z $DISABLE_TESTS ]; then
        return
    fi

    case $TRAVIS_OS_NAME in
        linux)
            td=$(mktemp -d)
            ;;
        osx)
            td=$(mktemp -d -t tmp)
            ;;
    esac

    # test crate
    cross init --name foo $td
    echo 'volatile-register = "0.1.0"' >> $td/Cargo.toml

    curl -L \
         https://raw.githubusercontent.com/posborne/cmsis-svd/python-0.4/data/STMicro/STM32F30x.svd \
         > $td/STM32F30x.svd

    curl -L \
         https://raw.githubusercontent.com/posborne/cmsis-svd/python-0.4/data/Nordic/nrf51.svd \
         > $td/nrf51.svd

    # test the generated code
    svd=STM32F30x.svd
    test_gen
    test_gen dbgmcu
    test_gen gpioa
    test_gen gpioc
    test_gen i2c1
    test_gen rcc
    test_gen spi1
    test_gen tim2
    test_gen tim3
    test_gen tim6

    # Test register arrays
    svd=nrf51.svd
    test_gen
    test_gen gpio
    test_gen timer

    rm -rf $td
}

if [ -z $TRAVIS_TAG ]; then
    main
fi
